#!/usr/bin/env python3

import curses
import os
import glob
import shutil
from pathlib import Path
from enum import Enum
import subprocess
import sys
from datetime import datetime, timedelta
import tempfile

class View(Enum):
    GENERAL = "general"    # User level (~/.claude/agents)
    PROJECT = "project"    # Project level (.claude/agents)

class AgentManager:
    def __init__(self):
        self.script_dir = Path(__file__).parent.absolute()
        self.agents_collection = self.script_dir / "agents-collection"
        self.user_agents = Path.home() / ".claude" / "agents"
        self.project_root = self.detect_project()
        self.project_agents = self.project_root / ".claude" / "agents" if self.project_root else None
        
        self.current_view = View.GENERAL
        self.current_index = 0
        self.agents_by_category = {}
        self.flattened_agents = []
        self.original_state = {}  # Track original installation state
        self.current_state = {}   # Track current selection state
        self.changes = {}          # Track changes (added/removed)
        
        self.load_agents()
    
    def detect_project(self):
        """Detect git project root"""
        current = Path.cwd()
        while current != current.parent:
            if (current / ".git").exists():
                return current
            current = current.parent
        return None
    
    def is_new_agent(self, file_path):
        """Check if agent file was created in last 48 hours"""
        try:
            mtime = file_path.stat().st_mtime
            age = datetime.now() - datetime.fromtimestamp(mtime)
            return age < timedelta(hours=48)
        except:
            return False
    
    def get_agent_info(self, file_path):
        """Extract agent name and description from file"""
        name = file_path.stem
        desc = "No description"
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                for line in f:
                    if line.startswith('description:'):
                        desc = line.replace('description:', '').strip()[:60]
                        break
        except:
            pass
        return name, desc
    
    def load_agents(self):
        """Load all agents organized by category"""
        self.agents_by_category = {
            'platform': [],
            'frontend': [],
            'backend': [],
            'infrastructure': []
        }
        
        # Determine which directory to check based on view
        check_dir = self.user_agents if self.current_view == View.GENERAL else self.project_agents
        
        # Load all agents from collection
        for category in self.agents_by_category.keys():
            category_path = self.agents_collection / category
            if category_path.exists():
                for file in sorted(category_path.glob("*.md")):
                    name, desc = self.get_agent_info(file)
                    
                    # Check if installed
                    installed = False
                    if check_dir and check_dir.exists():
                        installed = (check_dir / f"{name}.md").exists()
                    
                    agent = {
                        'type': 'agent',
                        'name': name,
                        'description': desc,
                        'category': category,
                        'path': file,
                        'installed': installed,
                        'is_new': self.is_new_agent(file)
                    }
                    
                    self.agents_by_category[category].append(agent)
                    
                    # Track original state
                    agent_key = f"{category}/{name}"
                    self.original_state[agent_key] = installed
                    self.current_state[agent_key] = installed
                    self.changes[agent_key] = None  # None = no change
        
        # Flatten for navigation
        self.flattened_agents = []
        for category in ['platform', 'frontend', 'backend', 'infrastructure']:
            if self.agents_by_category[category]:
                self.flattened_agents.append({'type': 'category', 'name': category})
                self.flattened_agents.extend(self.agents_by_category[category])
    
    def toggle_agent(self, agent):
        """Toggle agent selection and track changes"""
        agent_key = f"{agent['category']}/{agent['name']}"
        
        # Toggle current state
        self.current_state[agent_key] = not self.current_state[agent_key]
        
        # Determine change type
        if self.current_state[agent_key] == self.original_state[agent_key]:
            self.changes[agent_key] = None  # Back to original
        elif self.current_state[agent_key]:
            self.changes[agent_key] = 'add'  # Will be added
        else:
            self.changes[agent_key] = 'remove'  # Will be removed
    
    def get_changes_summary(self):
        """Get summary of pending changes"""
        adds = [k.split('/')[1] for k, v in self.changes.items() if v == 'add']
        removes = [k.split('/')[1] for k, v in self.changes.items() if v == 'remove']
        return adds, removes
    
    def save_changes(self):
        """Apply all changes to filesystem"""
        target_dir = self.user_agents if self.current_view == View.GENERAL else self.project_agents
        target_dir.mkdir(parents=True, exist_ok=True)
        
        for agent_key, change in self.changes.items():
            if change is None:
                continue
                
            category, name = agent_key.split('/')
            source_file = self.agents_collection / category / f"{name}.md"
            target_file = target_dir / f"{name}.md"
            
            if change == 'add' and source_file.exists():
                shutil.copy2(source_file, target_file)
            elif change == 'remove' and target_file.exists():
                target_file.unlink()
        
        # Reload to reflect changes
        self.load_agents()
    
    def view_agent_file(self, agent):
        """View agent file in read-only mode using system editor"""
        if 'path' in agent and agent['path'].exists():
            # Use less or cat as fallback
            editor = os.environ.get('PAGER', 'less')
            if not shutil.which(editor):
                editor = 'cat'
            
            # Create a temporary file with read-only notice
            with tempfile.NamedTemporaryFile(mode='w', suffix='.md', delete=False) as tmp:
                tmp.write(f"# VIEWING (READ-ONLY): {agent['name']}\n")
                tmp.write(f"# Category: {agent['category']}\n")
                tmp.write(f"# {'=' * 60}\n\n")
                with open(agent['path'], 'r') as original:
                    tmp.write(original.read())
                tmp_path = tmp.name
            
            # View the file
            curses.endwin()  # Temporarily leave curses mode
            subprocess.call([editor, tmp_path])
            os.unlink(tmp_path)  # Clean up temp file
            
            # Return to curses
            curses.doupdate()
    
    def draw_header(self, stdscr, height, width):
        """Draw header with view indicator"""
        view_text = "Vista General (Usuario)" if self.current_view == View.GENERAL else f"Vista Proyecto: {self.project_root.name}"
        header = f"╔{'═' * (width-2)}╗"
        footer = f"╚{'═' * (width-2)}╝"
        
        stdscr.addstr(0, 0, header, curses.color_pair(2) | curses.A_BOLD)
        stdscr.addstr(1, 0, "║", curses.color_pair(2) | curses.A_BOLD)
        stdscr.addstr(1, width-1, "║", curses.color_pair(2) | curses.A_BOLD)
        
        # Center the title
        title = f"Claude Agent Manager - {view_text}"
        title_x = (width - len(title)) // 2
        stdscr.addstr(1, title_x, title, curses.color_pair(2) | curses.A_BOLD)
        
        stdscr.addstr(2, 0, footer, curses.color_pair(2) | curses.A_BOLD)
        
        # Show pending changes count
        adds, removes = self.get_changes_summary()
        if adds or removes:
            changes_text = "Cambios pendientes: "
            if adds:
                changes_text += f"+{len(adds)} "
            if removes:
                changes_text += f"-{len(removes)}"
            stdscr.addstr(3, 2, changes_text, curses.color_pair(4) | curses.A_BOLD)
    
    def draw_agents_list(self, stdscr, height, width):
        """Draw categorized agent list with color coding"""
        start_y = 5
        visible_height = height - 8
        
        # Calculate visible range
        if self.current_index >= visible_height:
            scroll_offset = self.current_index - visible_height + 1
        else:
            scroll_offset = 0
        
        visible_end = min(len(self.flattened_agents), scroll_offset + visible_height)
        
        y = start_y
        for i in range(scroll_offset, visible_end):
            item = self.flattened_agents[i]
            
            if item['type'] == 'category':
                # Draw category header
                category_text = f"═══ {item['name'].upper()} ═══"
                stdscr.addstr(y, 2, category_text, curses.color_pair(5) | curses.A_BOLD)
            else:
                # Draw agent
                agent_key = f"{item['category']}/{item['name']}"
                is_selected = self.current_state[agent_key]
                change = self.changes[agent_key]
                
                # Prepare display elements
                marker = "▶ " if i == self.current_index else "  "
                checkbox = "[✓] " if is_selected else "[ ] "
                new_marker = "*" if item['is_new'] else " "
                
                # Determine color based on change
                if change == 'add':
                    color = curses.color_pair(3)  # Green
                    status_symbol = " +"
                elif change == 'remove':
                    color = curses.color_pair(1)  # Red
                    status_symbol = " -"
                else:
                    color = curses.color_pair(7)  # Normal
                    status_symbol = "  "
                
                # Build display string
                display = f"{marker}{checkbox}{new_marker}{item['name'][:30]}{status_symbol}"
                
                # Apply highlighting for current item
                if i == self.current_index:
                    stdscr.addstr(y, 2, display, color | curses.A_REVERSE)
                else:
                    stdscr.addstr(y, 2, display, color)
                
                # Show description
                desc_x = 45
                if desc_x < width - 2:
                    desc = item['description'][:width - desc_x - 2]
                    stdscr.addstr(y, desc_x, desc, curses.color_pair(6))
            
            y += 1
        
        # Scroll indicator
        if len(self.flattened_agents) > visible_height:
            scroll_text = f"({scroll_offset + 1}-{visible_end}/{len(self.flattened_agents)})"
            stdscr.addstr(height - 3, width - len(scroll_text) - 2, scroll_text, curses.color_pair(6))
    
    def draw_instructions(self, stdscr, height, width):
        """Draw bottom instructions"""
        instructions = [
            "[↑/↓] Navegar",
            "[SPACE] Seleccionar",
            "[1] Vista General",
            "[2] Vista Proyecto" if self.project_root else "",
            "[v] Ver archivo",
            "[s] Guardar cambios",
            "[r] Recargar",
            "[q] Salir"
        ]
        
        # Filter empty instructions
        instructions = [i for i in instructions if i]
        
        # Draw separator
        stdscr.addstr(height - 2, 0, "─" * width, curses.color_pair(6))
        
        # Draw instructions
        inst_text = "  ".join(instructions)
        if len(inst_text) < width:
            stdscr.addstr(height - 1, 2, inst_text, curses.color_pair(6))
    
    def show_confirmation(self, stdscr, height, width):
        """Show confirmation dialog for saves"""
        adds, removes = self.get_changes_summary()
        
        if not adds and not removes:
            return self.show_message(stdscr, height, width, "No hay cambios pendientes", 2)
        
        # Create confirmation window
        dialog_height = 10 + len(adds) + len(removes)
        dialog_width = 60
        dialog_y = (height - dialog_height) // 2
        dialog_x = (width - dialog_width) // 2
        
        # Create window
        dialog = curses.newwin(dialog_height, dialog_width, dialog_y, dialog_x)
        dialog.box()
        
        # Title
        title = " Confirmar Cambios "
        dialog.addstr(0, (dialog_width - len(title)) // 2, title, curses.A_BOLD)
        
        y = 2
        target = "Usuario" if self.current_view == View.GENERAL else "Proyecto"
        dialog.addstr(y, 2, f"Destino: {target}", curses.A_BOLD)
        y += 2
        
        # Show additions
        if adds:
            dialog.addstr(y, 2, f"Se añadirán ({len(adds)}):", curses.color_pair(3) | curses.A_BOLD)
            y += 1
            for agent in adds[:5]:
                dialog.addstr(y, 4, f"+ {agent}", curses.color_pair(3))
                y += 1
            if len(adds) > 5:
                dialog.addstr(y, 4, f"... y {len(adds) - 5} más", curses.color_pair(3))
                y += 1
            y += 1
        
        # Show removals
        if removes:
            dialog.addstr(y, 2, f"Se eliminarán ({len(removes)}):", curses.color_pair(1) | curses.A_BOLD)
            y += 1
            for agent in removes[:5]:
                dialog.addstr(y, 4, f"- {agent}", curses.color_pair(1))
                y += 1
            if len(removes) > 5:
                dialog.addstr(y, 4, f"... y {len(removes) - 5} más", curses.color_pair(1))
                y += 1
        
        # Prompt
        dialog.addstr(dialog_height - 2, 2, "¿Confirmar? [s/n]", curses.A_BOLD)
        dialog.refresh()
        
        # Get response
        while True:
            key = dialog.getch()
            if key in [ord('s'), ord('S'), ord('y'), ord('Y')]:
                return True
            elif key in [ord('n'), ord('N'), 27]:  # ESC also cancels
                return False
    
    def show_message(self, stdscr, height, width, message, duration=1):
        """Show a temporary message"""
        msg_y = height // 2
        msg_x = (width - len(message) - 4) // 2
        
        # Create small window for message
        msg_win = curses.newwin(3, len(message) + 4, msg_y, msg_x)
        msg_win.box()
        msg_win.addstr(1, 2, message)
        msg_win.refresh()
        
        curses.napms(duration * 1000)
        return False
    
    def run(self, stdscr):
        """Main UI loop"""
        # Setup colors
        curses.curs_set(0)  # Hide cursor
        curses.init_pair(1, curses.COLOR_RED, curses.COLOR_BLACK)    # Remove
        curses.init_pair(2, curses.COLOR_BLUE, curses.COLOR_BLACK)   # Headers
        curses.init_pair(3, curses.COLOR_GREEN, curses.COLOR_BLACK)  # Add
        curses.init_pair(4, curses.COLOR_YELLOW, curses.COLOR_BLACK) # Warning
        curses.init_pair(5, curses.COLOR_CYAN, curses.COLOR_BLACK)   # Category
        curses.init_pair(6, curses.COLOR_WHITE, curses.COLOR_BLACK)  # Dim
        curses.init_pair(7, curses.COLOR_WHITE, curses.COLOR_BLACK)  # Normal
        
        while True:
            height, width = stdscr.getmaxyx()
            stdscr.clear()
            
            # Draw interface
            self.draw_header(stdscr, height, width)
            self.draw_agents_list(stdscr, height, width)
            self.draw_instructions(stdscr, height, width)
            
            stdscr.refresh()
            
            # Handle input
            key = stdscr.getch()
            
            # Navigation
            if key == curses.KEY_UP:
                if self.current_index > 0:
                    self.current_index -= 1
                    # Skip category headers
                    while (self.current_index > 0 and 
                           self.flattened_agents[self.current_index]['type'] == 'category'):
                        self.current_index -= 1
            
            elif key == curses.KEY_DOWN:
                if self.current_index < len(self.flattened_agents) - 1:
                    self.current_index += 1
                    # Skip category headers
                    while (self.current_index < len(self.flattened_agents) - 1 and 
                           self.flattened_agents[self.current_index]['type'] == 'category'):
                        self.current_index += 1
            
            # Space - toggle selection
            elif key == ord(' '):
                if (self.current_index < len(self.flattened_agents) and 
                    self.flattened_agents[self.current_index]['type'] == 'agent'):
                    self.toggle_agent(self.flattened_agents[self.current_index])
            
            # View switching
            elif key == ord('1'):
                if self.current_view != View.GENERAL:
                    # Save any pending changes warning
                    adds, removes = self.get_changes_summary()
                    if adds or removes:
                        self.show_message(stdscr, height, width, 
                                        "⚠ Cambios pendientes no guardados", 2)
                    self.current_view = View.GENERAL
                    self.current_index = 0
                    self.load_agents()
            
            elif key == ord('2') and self.project_root:
                if self.current_view != View.PROJECT:
                    # Save any pending changes warning
                    adds, removes = self.get_changes_summary()
                    if adds or removes:
                        self.show_message(stdscr, height, width, 
                                        "⚠ Cambios pendientes no guardados", 2)
                    self.current_view = View.PROJECT
                    self.current_index = 0
                    self.load_agents()
            
            # View file
            elif key == ord('v') or key == ord('V'):
                if (self.current_index < len(self.flattened_agents) and 
                    self.flattened_agents[self.current_index]['type'] == 'agent'):
                    self.view_agent_file(self.flattened_agents[self.current_index])
            
            # Save changes
            elif key == ord('s') or key == ord('S'):
                if self.show_confirmation(stdscr, height, width):
                    self.save_changes()
                    self.show_message(stdscr, height, width, "✓ Cambios guardados", 1)
            
            # Reload
            elif key == ord('r') or key == ord('R'):
                adds, removes = self.get_changes_summary()
                if adds or removes:
                    self.show_message(stdscr, height, width, 
                                    "⚠ Cambios pendientes perdidos", 2)
                self.load_agents()
                self.show_message(stdscr, height, width, "✓ Recargado", 1)
            
            # Quit
            elif key == ord('q') or key == ord('Q'):
                adds, removes = self.get_changes_summary()
                if adds or removes:
                    if not self.show_confirmation(stdscr, height, width):
                        continue
                    else:
                        self.save_changes()
                break
            
            # ESC - cancel changes for current view
            elif key == 27:
                self.load_agents()
                self.show_message(stdscr, height, width, "✓ Cambios cancelados", 1)

def main():
    try:
        manager = AgentManager()
        curses.wrapper(manager.run)
        print("\n¡Hasta luego!")
    except KeyboardInterrupt:
        print("\n¡Hasta luego!")
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()