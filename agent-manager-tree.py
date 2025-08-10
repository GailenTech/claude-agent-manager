#!/usr/bin/env python3

import curses
import os
from pathlib import Path
import shutil
from enum import Enum
from datetime import datetime, timedelta
import tempfile
import sys

class View(Enum):
    GENERAL = "general"    # User level (~/.claude/agents)
    PROJECT = "project"    # Project level (.claude/agents)

class TreeNode:
    def __init__(self, name, path, is_folder=False, level=0):
        self.name = name
        self.path = path
        self.is_folder = is_folder
        self.level = level
        self.expanded = level < 2  # Auto-expand first 2 levels
        self.children = []
        self.parent = None
        self.selected = False
        self.installed = False
        self.description = ""
        self.is_new = False
        self.agent_count = 0  # For folders
        self.changes_summary = {'add': 0, 'remove': 0}  # Track changes in folder
        
    def get_display_name(self):
        """Get display name with folder indicators"""
        if self.is_folder:
            if self.expanded:
                prefix = "▼ "
            else:
                prefix = "▶ "
            
            if self.agent_count > 0:
                return f"{prefix}{self.name.upper() if self.level == 0 else self.name}"
            else:
                return f"{prefix}{self.name.upper() if self.level == 0 else self.name}"
        else:
            return self.name
    
    def get_agent_count_recursive(self):
        """Count all agents in this folder and subfolders"""
        if not self.is_folder:
            return 1
        
        count = 0
        for child in self.children:
            if child.is_folder:
                count += child.get_agent_count_recursive()
            else:
                count += 1
        return count
    
    def toggle_expand(self):
        """Toggle folder expansion"""
        if self.is_folder:
            self.expanded = not self.expanded
    
    def expand_all(self):
        """Expand this folder and all subfolders"""
        if self.is_folder:
            self.expanded = True
            for child in self.children:
                child.expand_all()
    
    def collapse_all(self):
        """Collapse this folder and all subfolders"""
        if self.is_folder:
            self.expanded = False
            for child in self.children:
                child.collapse_all()
    
    def update_changes_summary(self, changes_dict):
        """Update changes summary for this node and propagate to parents"""
        if not self.is_folder:
            return
        
        # Reset counters
        self.changes_summary = {'add': 0, 'remove': 0}
        
        # Count changes in direct children and subfolders
        for child in self.children:
            if child.is_folder:
                # Recursively update child folders first
                child.update_changes_summary(changes_dict)
                # Add child folder's changes to this folder
                self.changes_summary['add'] += child.changes_summary['add']
                self.changes_summary['remove'] += child.changes_summary['remove']
            else:
                # Check if this agent has changes
                relative_path = str(child.path.relative_to(child.path.parent.parent.parent)) if child.path.parent.parent.parent.exists() else child.name
                for key, change_type in changes_dict.items():
                    if change_type and child.name in key:
                        if change_type == 'add':
                            self.changes_summary['add'] += 1
                        elif change_type == 'remove':
                            self.changes_summary['remove'] += 1
    
    def get_changes_display(self):
        """Get formatted string for changes display"""
        if not self.is_folder or (self.changes_summary['add'] == 0 and self.changes_summary['remove'] == 0):
            return ""
        
        parts = []
        if self.changes_summary['add'] > 0:
            parts.append(f"+{self.changes_summary['add']}")
        if self.changes_summary['remove'] > 0:
            parts.append(f"-{self.changes_summary['remove']}")
        
        return f" [{' '.join(parts)}]" if parts else ""

class AgentManagerTree:
    def __init__(self):
        self.script_dir = Path(__file__).parent.absolute()
        collection_path = os.environ.get('CLAUDE_AGENT_COLLECTION')
        if collection_path:
            self.agents_collection = Path(collection_path)
        else:
            self.agents_collection = self.script_dir / "agents-collection"
        
        self.user_agents = Path.home() / ".claude" / "agents"
        self.project_root = self.detect_project()
        self.project_agents = self.project_root / ".claude" / "agents" if self.project_root else None
        
        self.current_view = View.GENERAL
        self.current_index = 0
        self.tree_root = TreeNode("root", self.agents_collection, is_folder=True, level=-1)
        self.flattened_nodes = []
        self.original_state = {}
        self.current_state = {}
        self.changes = {}
        
        self.build_tree()
        self.load_installation_state()
        self.flatten_tree()
    
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
        """Extract agent description from file"""
        desc = "No description"
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                for line in f:
                    if line.startswith('description:'):
                        desc = line.replace('description:', '').strip()[:60]
                        break
        except:
            pass
        return desc
    
    def build_tree(self):
        """Build tree structure from agents collection"""
        self.tree_root.children = []
        self._build_tree_recursive(self.agents_collection, self.tree_root, 0)
        
        # Update agent counts
        for child in self.tree_root.children:
            child.agent_count = child.get_agent_count_recursive()
    
    def _build_tree_recursive(self, path, parent_node, level):
        """Recursively build tree from filesystem"""
        try:
            items = sorted(path.iterdir())
            
            # First add subdirectories
            for item in items:
                if item.is_dir() and not item.name.startswith('.'):
                    folder_node = TreeNode(item.name, item, is_folder=True, level=level)
                    folder_node.parent = parent_node
                    parent_node.children.append(folder_node)
                    
                    # Recurse into subdirectory
                    self._build_tree_recursive(item, folder_node, level + 1)
            
            # Then add .md files
            for item in items:
                if item.is_file() and item.suffix == '.md':
                    agent_node = TreeNode(item.stem, item, is_folder=False, level=level)
                    agent_node.parent = parent_node
                    agent_node.description = self.get_agent_info(item)
                    agent_node.is_new = self.is_new_agent(item)
                    parent_node.children.append(agent_node)
                    
        except PermissionError:
            pass
    
    def load_installation_state(self):
        """Load which agents are installed"""
        check_dir = self.user_agents if self.current_view == View.GENERAL else self.project_agents
        
        self.original_state = {}
        self.current_state = {}
        self.changes = {}
        
        if check_dir and check_dir.exists():
            installed_files = set(f.stem for f in check_dir.glob("*.md"))
        else:
            installed_files = set()
        
        # Mark installed agents in tree
        self._mark_installed_recursive(self.tree_root, installed_files)
    
    def _mark_installed_recursive(self, node, installed_files):
        """Recursively mark installed agents"""
        if not node.is_folder:
            node.installed = node.name in installed_files
            node.selected = node.installed
            
            # Track state
            key = str(node.path.relative_to(self.agents_collection))
            self.original_state[key] = node.installed
            self.current_state[key] = node.installed
            self.changes[key] = None
        else:
            for child in node.children:
                self._mark_installed_recursive(child, installed_files)
    
    def flatten_tree(self):
        """Flatten tree to list for display, respecting expansion state"""
        self.flattened_nodes = []
        self._flatten_recursive(self.tree_root)
    
    def _flatten_recursive(self, node):
        """Recursively flatten tree"""
        # Don't include root node itself
        if node.level >= 0:
            self.flattened_nodes.append(node)
        
        # Only include children if folder is expanded or if it's root
        if node.is_folder and (node.expanded or node.level == -1):
            for child in node.children:
                self._flatten_recursive(child)
    
    def toggle_selection(self, node):
        """Toggle agent selection and track changes"""
        if node.is_folder:
            return
        
        node.selected = not node.selected
        
        key = str(node.path.relative_to(self.agents_collection))
        self.current_state[key] = node.selected
        
        if self.current_state[key] == self.original_state[key]:
            self.changes[key] = None
        elif self.current_state[key]:
            self.changes[key] = 'add'
        else:
            self.changes[key] = 'remove'
        
        # Update changes summary for all folders
        self.update_all_changes_summary()
    
    def update_all_changes_summary(self):
        """Update changes summary for entire tree"""
        for child in self.tree_root.children:
            child.update_changes_summary(self.changes)
    
    def get_changes_summary(self):
        """Get summary of pending changes"""
        adds = [Path(k).name for k, v in self.changes.items() if v == 'add']
        removes = [Path(k).name for k, v in self.changes.items() if v == 'remove']
        return adds, removes
    
    def save_changes(self):
        """Apply all changes to filesystem"""
        target_dir = self.user_agents if self.current_view == View.GENERAL else self.project_agents
        target_dir.mkdir(parents=True, exist_ok=True)
        
        for path_key, change in self.changes.items():
            if change is None:
                continue
            
            source_file = self.agents_collection / path_key
            agent_name = Path(path_key).stem
            target_file = target_dir / f"{agent_name}.md"
            
            if change == 'add' and source_file.exists():
                shutil.copy2(source_file, target_file)
            elif change == 'remove' and target_file.exists():
                target_file.unlink()
        
        # Reload state
        self.load_installation_state()
        self.flatten_tree()
    
    def view_agent_file(self, node):
        """View agent file in read-only mode"""
        if node.is_folder or not node.path.exists():
            return
        
        editor = os.environ.get('PAGER', 'less')
        if not shutil.which(editor):
            editor = 'cat'
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.md', delete=False) as tmp:
            tmp.write(f"# VIEWING (READ-ONLY): {node.name}\n")
            tmp.write(f"# Path: {node.path.relative_to(self.agents_collection)}\n")
            tmp.write(f"# {'=' * 60}\n\n")
            with open(node.path, 'r') as original:
                tmp.write(original.read())
            tmp_path = tmp.name
        
        curses.endwin()
        os.system(f"{editor} {tmp_path}")
        os.unlink(tmp_path)
        curses.doupdate()
    
    def draw_header(self, stdscr, height, width):
        """Draw header with view indicator"""
        view_text = "Vista General (Usuario)" if self.current_view == View.GENERAL else f"Vista Proyecto: {self.project_root.name}"
        
        stdscr.addstr(0, 0, "╔" + "═" * (width-2) + "╗", curses.color_pair(2) | curses.A_BOLD)
        stdscr.addstr(1, 0, "║", curses.color_pair(2) | curses.A_BOLD)
        stdscr.addstr(1, width-1, "║", curses.color_pair(2) | curses.A_BOLD)
        
        title = f"Claude Agent Manager - {view_text}"
        title_x = (width - len(title)) // 2
        stdscr.addstr(1, title_x, title, curses.color_pair(2) | curses.A_BOLD)
        
        stdscr.addstr(2, 0, "╚" + "═" * (width-2) + "╝", curses.color_pair(2) | curses.A_BOLD)
        
        adds, removes = self.get_changes_summary()
        if adds or removes:
            changes_text = "Cambios: "
            if adds:
                changes_text += f"+{len(adds)} "
            if removes:
                changes_text += f"-{len(removes)}"
            stdscr.addstr(3, 2, changes_text, curses.color_pair(4) | curses.A_BOLD)
    
    def draw_tree(self, stdscr, height, width):
        """Draw tree with proper indentation"""
        start_y = 5
        visible_height = height - 8
        
        # Calculate visible range
        if self.current_index >= visible_height:
            scroll_offset = self.current_index - visible_height + 1
        else:
            scroll_offset = 0
        
        visible_end = min(len(self.flattened_nodes), scroll_offset + visible_height)
        
        y = start_y
        for i in range(scroll_offset, visible_end):
            node = self.flattened_nodes[i]
            
            # Indentation
            indent = "  " * node.level
            
            # Selection marker
            if i == self.current_index:
                marker = "▶ "
                attr = curses.A_REVERSE
            else:
                marker = "  "
                attr = 0
            
            # Build display string
            if node.is_folder:
                # Folder display
                display_name = node.get_display_name()
                if node.agent_count > 0:
                    count_text = f" ({node.agent_count} agentes)"
                else:
                    count_text = " (vacío)"
                
                # Add changes summary if any
                changes_text = node.get_changes_display()
                
                line = f"{marker}{indent}{display_name}{count_text}{changes_text}"
                
                # Use different color for top-level folders
                if node.level == 0:
                    color = curses.color_pair(5) | curses.A_BOLD
                else:
                    color = curses.color_pair(6)
                
                # Apply change colors to the changes part
                if changes_text:
                    base_line = f"{marker}{indent}{display_name}{count_text}"
                    stdscr.addstr(y, 0, base_line[:width-len(changes_text)-1], color | attr)
                    
                    # Color the changes part
                    if node.changes_summary['add'] > 0 and node.changes_summary['remove'] > 0:
                        change_color = curses.color_pair(4)  # Yellow for mixed
                    elif node.changes_summary['add'] > 0:
                        change_color = curses.color_pair(3)  # Green for adds
                    else:
                        change_color = curses.color_pair(1)  # Red for removes
                    
                    stdscr.addstr(y, len(base_line), changes_text, change_color | attr)
                else:
                    stdscr.addstr(y, 0, line[:width-1], color | attr)
                
            else:
                # Agent display
                checkbox = "[✓] " if node.selected else "[ ] "
                new_marker = "*" if node.is_new else " "
                
                # Determine color based on changes
                key = str(node.path.relative_to(self.agents_collection))
                change = self.changes.get(key)
                
                if change == 'add':
                    color = curses.color_pair(3)  # Green
                    status = " +"
                elif change == 'remove':
                    color = curses.color_pair(1)  # Red
                    status = " -"
                else:
                    color = curses.color_pair(7)
                    status = ""
                
                line = f"{marker}{indent}  {checkbox}{new_marker}{node.name[:30]}{status}"
                stdscr.addstr(y, 0, line[:width//2], color | attr)
                
                # Description on the right
                if width > 80:
                    desc_x = min(50, width // 2)
                    desc = node.description[:width - desc_x - 2]
                    stdscr.addstr(y, desc_x, desc, curses.color_pair(6))
            
            y += 1
        
        # Scroll indicator
        if len(self.flattened_nodes) > visible_height:
            scroll_text = f"({scroll_offset + 1}-{visible_end}/{len(self.flattened_nodes)})"
            stdscr.addstr(height - 3, width - len(scroll_text) - 2, scroll_text, curses.color_pair(6))
    
    def draw_instructions(self, stdscr, height, width):
        """Draw instructions bar"""
        stdscr.addstr(height - 2, 0, "─" * width, curses.color_pair(6))
        
        instructions = "[↑/↓] Nav [→] Expandir [←] Colapsar [SPACE] Sel [*] Expandir todo [s] Guardar [q] Salir"
        
        if self.current_view == View.GENERAL:
            mode = "[1] General [2] Proyecto"
        else:
            mode = "[1] General [2] Proyecto"
        
        full_text = f"{instructions}  {mode}"
        
        if len(full_text) < width:
            stdscr.addstr(height - 1, 2, full_text[:width-3], curses.color_pair(6))
    
    def show_confirmation(self, stdscr, height, width):
        """Show confirmation dialog"""
        adds, removes = self.get_changes_summary()
        
        if not adds and not removes:
            return False
        
        dialog_height = 10 + len(adds) + len(removes)
        dialog_width = 60
        dialog_y = (height - dialog_height) // 2
        dialog_x = (width - dialog_width) // 2
        
        dialog = curses.newwin(dialog_height, dialog_width, dialog_y, dialog_x)
        dialog.box()
        
        title = " Confirmar Cambios "
        dialog.addstr(0, (dialog_width - len(title)) // 2, title, curses.A_BOLD)
        
        y = 2
        target = "Usuario" if self.current_view == View.GENERAL else "Proyecto"
        dialog.addstr(y, 2, f"Destino: {target}", curses.A_BOLD)
        y += 2
        
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
        
        if removes:
            dialog.addstr(y, 2, f"Se eliminarán ({len(removes)}):", curses.color_pair(1) | curses.A_BOLD)
            y += 1
            for agent in removes[:5]:
                dialog.addstr(y, 4, f"- {agent}", curses.color_pair(1))
                y += 1
            if len(removes) > 5:
                dialog.addstr(y, 4, f"... y {len(removes) - 5} más", curses.color_pair(1))
                y += 1
        
        dialog.addstr(dialog_height - 2, 2, "¿Confirmar? [s/n]", curses.A_BOLD)
        dialog.refresh()
        
        while True:
            key = dialog.getch()
            if key in [ord('s'), ord('S'), ord('y'), ord('Y')]:
                return True
            elif key in [ord('n'), ord('N'), 27]:
                return False
    
    def run(self, stdscr):
        """Main UI loop"""
        curses.curs_set(0)
        curses.init_pair(1, curses.COLOR_RED, curses.COLOR_BLACK)
        curses.init_pair(2, curses.COLOR_BLUE, curses.COLOR_BLACK)
        curses.init_pair(3, curses.COLOR_GREEN, curses.COLOR_BLACK)
        curses.init_pair(4, curses.COLOR_YELLOW, curses.COLOR_BLACK)
        curses.init_pair(5, curses.COLOR_CYAN, curses.COLOR_BLACK)
        curses.init_pair(6, curses.COLOR_WHITE, curses.COLOR_BLACK)
        curses.init_pair(7, curses.COLOR_WHITE, curses.COLOR_BLACK)
        
        while True:
            height, width = stdscr.getmaxyx()
            stdscr.clear()
            
            self.draw_header(stdscr, height, width)
            self.draw_tree(stdscr, height, width)
            self.draw_instructions(stdscr, height, width)
            
            stdscr.refresh()
            
            key = stdscr.getch()
            
            # Navigation
            if key == curses.KEY_UP:
                if self.current_index > 0:
                    self.current_index -= 1
            
            elif key == curses.KEY_DOWN:
                if self.current_index < len(self.flattened_nodes) - 1:
                    self.current_index += 1
            
            elif key == curses.KEY_RIGHT or key == ord('\n'):
                # Expand folder
                if self.current_index < len(self.flattened_nodes):
                    node = self.flattened_nodes[self.current_index]
                    if node.is_folder and not node.expanded:
                        node.expanded = True
                        self.flatten_tree()
            
            elif key == curses.KEY_LEFT:
                # Collapse folder or go to parent
                if self.current_index < len(self.flattened_nodes):
                    node = self.flattened_nodes[self.current_index]
                    if node.is_folder and node.expanded:
                        node.expanded = False
                        self.flatten_tree()
                    elif node.parent and node.parent.level >= 0:
                        # Jump to parent folder
                        for i, n in enumerate(self.flattened_nodes):
                            if n == node.parent:
                                self.current_index = i
                                break
            
            # Space - toggle selection or expand/collapse folder
            elif key == ord(' '):
                if self.current_index < len(self.flattened_nodes):
                    node = self.flattened_nodes[self.current_index]
                    if node.is_folder:
                        # Toggle expand/collapse for folders
                        node.toggle_expand()
                        self.flatten_tree()
                    else:
                        # Toggle selection for agents
                        self.toggle_selection(node)
            
            # Expand/collapse all
            elif key == ord('*'):
                for node in self.tree_root.children:
                    if all(child.expanded for child in self.tree_root.children if child.is_folder):
                        node.collapse_all()
                    else:
                        node.expand_all()
                self.flatten_tree()
            
            # View switching
            elif key == ord('1'):
                if self.current_view != View.GENERAL:
                    self.current_view = View.GENERAL
                    self.current_index = 0
                    self.load_installation_state()
                    self.flatten_tree()
            
            elif key == ord('2') and self.project_root:
                if self.current_view != View.PROJECT:
                    self.current_view = View.PROJECT
                    self.current_index = 0
                    self.load_installation_state()
                    self.flatten_tree()
            
            # View file
            elif key == ord('v') or key == ord('V'):
                if self.current_index < len(self.flattened_nodes):
                    node = self.flattened_nodes[self.current_index]
                    if not node.is_folder:
                        self.view_agent_file(node)
            
            # Save
            elif key == ord('s') or key == ord('S'):
                if self.show_confirmation(stdscr, height, width):
                    self.save_changes()
            
            # Select all in current folder
            elif key == ord('a') or key == ord('A'):
                if self.current_index < len(self.flattened_nodes):
                    current = self.flattened_nodes[self.current_index]
                    parent = current.parent if not current.is_folder else current
                    
                    for node in self.flattened_nodes:
                        if not node.is_folder and node.parent == parent:
                            node.selected = True
                            key = str(node.path.relative_to(self.agents_collection))
                            self.current_state[key] = True
                            if self.current_state[key] != self.original_state[key]:
                                self.changes[key] = 'add'
                            else:
                                self.changes[key] = None
                    
                    # Update changes summary
                    self.update_all_changes_summary()
            
            # Deselect all in current folder
            elif key == ord('n') or key == ord('N'):
                if self.current_index < len(self.flattened_nodes):
                    current = self.flattened_nodes[self.current_index]
                    parent = current.parent if not current.is_folder else current
                    
                    for node in self.flattened_nodes:
                        if not node.is_folder and node.parent == parent:
                            node.selected = False
                            key = str(node.path.relative_to(self.agents_collection))
                            self.current_state[key] = False
                            if self.current_state[key] != self.original_state[key]:
                                self.changes[key] = 'remove'
                            else:
                                self.changes[key] = None
                    
                    # Update changes summary
                    self.update_all_changes_summary()
            
            # Quit
            elif key == ord('q') or key == ord('Q'):
                adds, removes = self.get_changes_summary()
                if adds or removes:
                    if not self.show_confirmation(stdscr, height, width):
                        continue
                    else:
                        self.save_changes()
                break
            
            # ESC - cancel changes
            elif key == 27:
                self.load_installation_state()
                self.flatten_tree()

def main():
    try:
        manager = AgentManagerTree()
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