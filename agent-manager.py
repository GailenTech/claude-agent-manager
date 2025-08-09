#!/usr/bin/env python3

import curses
import os
import glob
import shutil
from pathlib import Path
from enum import Enum
import subprocess
import sys

class Mode(Enum):
    VIEW = "view"
    EDIT_USER = "edit_user"
    EDIT_PROJECT = "edit_project"
    INSTALL = "install"
    SYNC = "sync"

class AgentManager:
    def __init__(self):
        self.script_dir = Path(__file__).parent.absolute()
        self.agents_collection = self.script_dir / "agents-collection"
        self.user_agents = Path.home() / ".claude" / "agents"
        self.project_root = self.detect_project()
        self.project_agents = self.project_root / ".claude" / "agents" if self.project_root else None
        
        self.current_mode = Mode.VIEW
        self.current_index = 0
        self.agents = []
        self.selected = {}
        
        self.load_agents()
    
    def detect_project(self):
        """Detect git project root"""
        current = Path.cwd()
        while current != current.parent:
            if (current / ".git").exists():
                return current
            current = current.parent
        return None
    
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
        """Load all agents from different locations"""
        self.agents = []
        agent_dict = {}
        
        # Load from collection (available)
        for category in ['platform', 'frontend', 'backend', 'infrastructure']:
            category_path = self.agents_collection / category
            if category_path.exists():
                for file in category_path.glob("*.md"):
                    name, desc = self.get_agent_info(file)
                    agent_dict[name] = {
                        'name': name,
                        'description': desc,
                        'location': 'available',
                        'path': file
                    }
        
        # Check user level
        if self.user_agents.exists():
            for file in self.user_agents.glob("*.md"):
                name, desc = self.get_agent_info(file)
                if name in agent_dict:
                    agent_dict[name]['location'] = 'user'
                else:
                    agent_dict[name] = {
                        'name': name,
                        'description': desc,
                        'location': 'user',
                        'path': file
                    }
        
        # Check project level
        if self.project_agents and self.project_agents.exists():
            for file in self.project_agents.glob("*.md"):
                name, desc = self.get_agent_info(file)
                if name in agent_dict:
                    if agent_dict[name]['location'] == 'user':
                        agent_dict[name]['location'] = 'both'
                    elif agent_dict[name]['location'] == 'available':
                        agent_dict[name]['location'] = 'project'
                else:
                    agent_dict[name] = {
                        'name': name,
                        'description': desc,
                        'location': 'project',
                        'path': file
                    }
        
        # Convert to sorted list
        self.agents = sorted(agent_dict.values(), key=lambda x: x['name'])
        
        # Initialize selected state
        for agent in self.agents:
            if agent['name'] not in self.selected:
                self.selected[agent['name']] = False
    
    def draw_header(self, stdscr, height, width):
        """Draw header with mode title"""
        titles = {
            Mode.VIEW: "Claude Agent Manager - Vista General",
            Mode.EDIT_USER: "Editando Agentes - Nivel Usuario 🌍",
            Mode.EDIT_PROJECT: "Editando Agentes - Nivel Proyecto 📁",
            Mode.INSTALL: "Instalar Nuevos Agentes",
            Mode.SYNC: "Sincronizar Agentes 🔄"
        }
        
        title = titles[self.current_mode]
        header = f"╔{'═' * (width-2)}╗"
        footer = f"╚{'═' * (width-2)}╝"
        
        stdscr.addstr(0, 0, header, curses.color_pair(2) | curses.A_BOLD)
        stdscr.addstr(1, 0, "║", curses.color_pair(2) | curses.A_BOLD)
        stdscr.addstr(1, width-1, "║", curses.color_pair(2) | curses.A_BOLD)
        
        # Center the title
        title_x = (width - len(title)) // 2
        stdscr.addstr(1, title_x, title, curses.color_pair(2) | curses.A_BOLD)
        
        stdscr.addstr(2, 0, footer, curses.color_pair(2) | curses.A_BOLD)
        
        # Project info
        if self.project_root:
            project_info = f"📁 Proyecto: {self.project_root.name}"
            stdscr.addstr(3, 2, project_info, curses.color_pair(3))
        else:
            stdscr.addstr(3, 2, "⚠ Sin proyecto (solo modo usuario)", curses.color_pair(4))
    
    def draw_agents(self, stdscr, height, width):
        """Draw three-column agent list"""
        start_y = 5
        col_width = width // 3
        
        # Headers
        stdscr.addstr(start_y, 2, "🌍 Usuario", curses.color_pair(3) | curses.A_BOLD)
        if self.project_root:
            stdscr.addstr(start_y, col_width, "📁 Proyecto", curses.color_pair(4) | curses.A_BOLD)
        stdscr.addstr(start_y, col_width * 2, "📦 Disponibles", curses.color_pair(5) | curses.A_BOLD)
        
        # Separator
        stdscr.addstr(start_y + 1, 0, "─" * width, curses.color_pair(6))
        
        # Agent list
        visible_start = max(0, self.current_index - 10)
        visible_end = min(len(self.agents), visible_start + 15)
        
        y_offset = start_y + 2
        for i in range(visible_start, visible_end):
            agent = self.agents[i]
            y = y_offset + (i - visible_start)
            
            # Determine column based on location
            if agent['location'] == 'user':
                x = 2
            elif agent['location'] == 'project':
                x = col_width
            elif agent['location'] == 'available':
                x = col_width * 2
            else:  # both
                x = 2  # Show in user column
            
            # Selection marker
            marker = "▶ " if i == self.current_index else "  "
            
            # Checkbox for edit/install modes
            checkbox = ""
            if self.current_mode in [Mode.EDIT_USER, Mode.EDIT_PROJECT, Mode.INSTALL]:
                checkbox = "[✓] " if self.selected[agent['name']] else "[ ] "
            
            # Draw agent name
            name_display = f"{marker}{checkbox}{agent['name'][:20]}"
            
            if i == self.current_index:
                stdscr.addstr(y, x, name_display, curses.A_REVERSE)
            else:
                stdscr.addstr(y, x, name_display)
            
            # Draw in both columns if location is "both"
            if agent['location'] == 'both':
                both_display = f"  {checkbox}{agent['name'][:20]}"
                stdscr.addstr(y, col_width, both_display)
    
    def draw_details(self, stdscr, height, width):
        """Draw details panel on the right"""
        if not self.agents:
            return
            
        panel_x = (width * 3) // 4
        panel_y = 5
        panel_width = width - panel_x - 2
        
        agent = self.agents[self.current_index]
        
        # Draw panel border
        for i in range(12):
            if panel_y + i < height - 3:
                stdscr.addstr(panel_y + i, panel_x - 1, "│", curses.color_pair(6))
        
        # Panel title
        stdscr.addstr(panel_y, panel_x, "Detalles", curses.color_pair(5) | curses.A_BOLD)
        
        # Agent details
        stdscr.addstr(panel_y + 2, panel_x, f"Nombre: {agent['name'][:panel_width-8]}", curses.A_BOLD)
        
        # Location status
        stdscr.addstr(panel_y + 4, panel_x, "Estado:", curses.A_BOLD)
        location_text = {
            'user': "✓ Usuario",
            'project': "✓ Proyecto",
            'both': "✓ Usuario + Proyecto",
            'available': "○ No instalado"
        }
        color = {
            'user': 3,
            'project': 4,
            'both': 3,
            'available': 5
        }
        stdscr.addstr(panel_y + 5, panel_x + 2, location_text[agent['location']], 
                     curses.color_pair(color[agent['location']]))
        
        # Description
        stdscr.addstr(panel_y + 7, panel_x, "Descripción:", curses.A_BOLD)
        desc_lines = [agent['description'][i:i+panel_width-2] 
                     for i in range(0, len(agent['description']), panel_width-2)]
        for i, line in enumerate(desc_lines[:3]):
            if panel_y + 8 + i < height - 3:
                stdscr.addstr(panel_y + 8 + i, panel_x, line)
    
    def draw_instructions(self, stdscr, height, width):
        """Draw bottom instructions"""
        y = height - 2
        
        instructions = {
            Mode.VIEW: "[↑/↓] Navegar  [1] Edit Usuario  [2] Edit Proyecto  [3] Instalar  [4] Sync  [q] Salir",
            Mode.EDIT_USER: "[↑/↓] Navegar  [SPACE] Seleccionar  [a] Todos  [n] Ninguno  [s] Guardar  [ESC] Volver",
            Mode.EDIT_PROJECT: "[↑/↓] Navegar  [SPACE] Seleccionar  [a] Todos  [n] Ninguno  [s] Guardar  [ESC] Volver",
            Mode.INSTALL: "[↑/↓] Navegar  [SPACE] Seleccionar  [1] →Usuario  [2] →Proyecto  [ESC] Volver",
            Mode.SYNC: "[1] Proyecto→Usuario  [2] Usuario→Proyecto  [3] Bidireccional  [ESC] Volver"
        }
        
        stdscr.addstr(y - 1, 0, "─" * width, curses.color_pair(6))
        stdscr.addstr(y, 2, instructions[self.current_mode], curses.color_pair(6))
    
    def handle_edit_mode(self, target):
        """Pre-select installed agents for edit mode"""
        for agent in self.agents:
            if target == 'user':
                self.selected[agent['name']] = agent['location'] in ['user', 'both']
            elif target == 'project':
                self.selected[agent['name']] = agent['location'] in ['project', 'both']
    
    def save_changes(self, target):
        """Save agent selection changes"""
        if target == 'user':
            dest_dir = self.user_agents
        else:
            dest_dir = self.project_agents
        
        dest_dir.mkdir(parents=True, exist_ok=True)
        
        for agent in self.agents:
            dest_file = dest_dir / f"{agent['name']}.md"
            
            if self.selected[agent['name']]:
                # Should be installed
                if not dest_file.exists():
                    # Find source and copy
                    for category in ['platform', 'frontend', 'backend', 'infrastructure']:
                        source = self.agents_collection / category / f"{agent['name']}.md"
                        if source.exists():
                            shutil.copy2(source, dest_file)
                            break
            else:
                # Should not be installed
                if dest_file.exists():
                    dest_file.unlink()
        
        self.load_agents()
    
    def install_selected(self, target):
        """Install selected agents"""
        if target == 'user':
            dest_dir = self.user_agents
        else:
            dest_dir = self.project_agents
        
        dest_dir.mkdir(parents=True, exist_ok=True)
        
        for agent in self.agents:
            if self.selected[agent['name']] and agent['location'] == 'available':
                # Find source and copy
                for category in ['platform', 'frontend', 'backend', 'infrastructure']:
                    source = self.agents_collection / category / f"{agent['name']}.md"
                    if source.exists():
                        dest_file = dest_dir / f"{agent['name']}.md"
                        shutil.copy2(source, dest_file)
                        break
        
        self.load_agents()
    
    def sync_agents(self, direction):
        """Sync agents between user and project"""
        if direction == 'project_to_user':
            if self.project_agents and self.project_agents.exists():
                self.user_agents.mkdir(parents=True, exist_ok=True)
                for file in self.project_agents.glob("*.md"):
                    shutil.copy2(file, self.user_agents / file.name)
        
        elif direction == 'user_to_project':
            if self.user_agents.exists() and self.project_agents:
                self.project_agents.mkdir(parents=True, exist_ok=True)
                for file in self.user_agents.glob("*.md"):
                    shutil.copy2(file, self.project_agents / file.name)
        
        elif direction == 'bidirectional':
            if self.user_agents.exists() and self.project_agents and self.project_agents.exists():
                # User to project
                self.project_agents.mkdir(parents=True, exist_ok=True)
                for file in self.user_agents.glob("*.md"):
                    shutil.copy2(file, self.project_agents / file.name)
                # Project to user
                self.user_agents.mkdir(parents=True, exist_ok=True)
                for file in self.project_agents.glob("*.md"):
                    shutil.copy2(file, self.user_agents / file.name)
        
        self.load_agents()
    
    def run(self, stdscr):
        """Main UI loop"""
        # Setup colors
        curses.curs_set(0)  # Hide cursor
        curses.init_pair(1, curses.COLOR_WHITE, curses.COLOR_BLACK)
        curses.init_pair(2, curses.COLOR_BLUE, curses.COLOR_BLACK)
        curses.init_pair(3, curses.COLOR_GREEN, curses.COLOR_BLACK)
        curses.init_pair(4, curses.COLOR_YELLOW, curses.COLOR_BLACK)
        curses.init_pair(5, curses.COLOR_CYAN, curses.COLOR_BLACK)
        curses.init_pair(6, curses.COLOR_WHITE, curses.COLOR_BLACK)
        
        while True:
            height, width = stdscr.getmaxyx()
            stdscr.clear()
            
            # Draw interface
            self.draw_header(stdscr, height, width)
            self.draw_agents(stdscr, height, width)
            self.draw_details(stdscr, height, width)
            self.draw_instructions(stdscr, height, width)
            
            stdscr.refresh()
            
            # Handle input
            key = stdscr.getch()
            
            # ESC key
            if key == 27:
                if self.current_mode != Mode.VIEW:
                    self.current_mode = Mode.VIEW
                    for name in self.selected:
                        self.selected[name] = False
                    self.load_agents()
            
            # Arrow keys
            elif key == curses.KEY_UP:
                if self.current_index > 0:
                    self.current_index -= 1
            
            elif key == curses.KEY_DOWN:
                if self.current_index < len(self.agents) - 1:
                    self.current_index += 1
            
            # Space - select/deselect
            elif key == ord(' '):
                if self.current_mode in [Mode.EDIT_USER, Mode.EDIT_PROJECT, Mode.INSTALL]:
                    agent_name = self.agents[self.current_index]['name']
                    self.selected[agent_name] = not self.selected[agent_name]
            
            # Mode changes and actions
            elif key == ord('1'):
                if self.current_mode == Mode.VIEW:
                    self.current_mode = Mode.EDIT_USER
                    self.handle_edit_mode('user')
                elif self.current_mode == Mode.INSTALL:
                    self.install_selected('user')
                    self.current_mode = Mode.VIEW
                elif self.current_mode == Mode.SYNC:
                    self.sync_agents('project_to_user')
                    self.current_mode = Mode.VIEW
            
            elif key == ord('2'):
                if self.current_mode == Mode.VIEW and self.project_root:
                    self.current_mode = Mode.EDIT_PROJECT
                    self.handle_edit_mode('project')
                elif self.current_mode == Mode.INSTALL and self.project_root:
                    self.install_selected('project')
                    self.current_mode = Mode.VIEW
                elif self.current_mode == Mode.SYNC:
                    self.sync_agents('user_to_project')
                    self.current_mode = Mode.VIEW
            
            elif key == ord('3'):
                if self.current_mode == Mode.VIEW:
                    self.current_mode = Mode.INSTALL
                    for name in self.selected:
                        self.selected[name] = False
                elif self.current_mode == Mode.SYNC:
                    self.sync_agents('bidirectional')
                    self.current_mode = Mode.VIEW
            
            elif key == ord('4'):
                if self.current_mode == Mode.VIEW:
                    self.current_mode = Mode.SYNC
            
            # Select all/none
            elif key == ord('a') or key == ord('A'):
                if self.current_mode in [Mode.EDIT_USER, Mode.EDIT_PROJECT, Mode.INSTALL]:
                    for name in self.selected:
                        self.selected[name] = True
            
            elif key == ord('n') or key == ord('N'):
                if self.current_mode in [Mode.EDIT_USER, Mode.EDIT_PROJECT, Mode.INSTALL]:
                    for name in self.selected:
                        self.selected[name] = False
            
            # Save
            elif key == ord('s') or key == ord('S'):
                if self.current_mode == Mode.EDIT_USER:
                    self.save_changes('user')
                    self.current_mode = Mode.VIEW
                elif self.current_mode == Mode.EDIT_PROJECT:
                    self.save_changes('project')
                    self.current_mode = Mode.VIEW
            
            # Quit
            elif key == ord('q') or key == ord('Q'):
                if self.current_mode == Mode.VIEW:
                    break

def main():
    try:
        manager = AgentManager()
        curses.wrapper(manager.run)
    except KeyboardInterrupt:
        print("\n¡Hasta luego!")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()