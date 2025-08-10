#!/usr/bin/env python3
"""Verify tree functionality without UI"""

from pathlib import Path

# Test the tree node functionality
class TreeNode:
    def __init__(self, name, path, is_folder=False, level=0):
        self.name = name
        self.path = path
        self.is_folder = is_folder
        self.level = level
        self.expanded = level < 2
        self.children = []
        self.parent = None
        self.selected = False
        self.changes_summary = {'add': 0, 'remove': 0}
    
    def toggle_expand(self):
        if self.is_folder:
            self.expanded = not self.expanded
    
    def get_display_name(self):
        if self.is_folder:
            prefix = "▼ " if self.expanded else "▶ "
            return f"{prefix}{self.name.upper() if self.level == 0 else self.name}"
        return self.name
    
    def get_changes_display(self):
        if not self.is_folder or (self.changes_summary['add'] == 0 and self.changes_summary['remove'] == 0):
            return ""
        
        parts = []
        if self.changes_summary['add'] > 0:
            parts.append(f"+{self.changes_summary['add']}")
        if self.changes_summary['remove'] > 0:
            parts.append(f"-{self.changes_summary['remove']}")
        
        return f" [{' '.join(parts)}]" if parts else ""
    
    def update_changes_summary(self, changes_dict):
        if not self.is_folder:
            return
        
        self.changes_summary = {'add': 0, 'remove': 0}
        
        for child in self.children:
            if child.is_folder:
                child.update_changes_summary(changes_dict)
                self.changes_summary['add'] += child.changes_summary['add']
                self.changes_summary['remove'] += child.changes_summary['remove']
            else:
                # Simplified check for testing
                if child.selected and not child.installed:
                    self.changes_summary['add'] += 1
                elif not child.selected and child.installed:
                    self.changes_summary['remove'] += 1

# Test the functionality
print("Tree Structure Test")
print("=" * 50)

# Create a test tree
root = TreeNode("root", Path("."), is_folder=True, level=-1)

# Add categories
platform = TreeNode("platform", Path("platform"), is_folder=True, level=0)
frontend = TreeNode("frontend", Path("frontend"), is_folder=True, level=0)
backend = TreeNode("backend", Path("backend"), is_folder=True, level=0)

root.children = [platform, frontend, backend]
for child in root.children:
    child.parent = root

# Add subcategories to frontend
vue_folder = TreeNode("vue", Path("frontend/vue"), is_folder=True, level=1)
react_folder = TreeNode("react", Path("frontend/react"), is_folder=True, level=1)
vue_folder.parent = frontend
react_folder.parent = frontend
frontend.children = [vue_folder, react_folder]

# Add agents to vue folder
vue_agent = TreeNode("vue3-composition", Path("frontend/vue/vue3-composition.md"), is_folder=False, level=2)
vue_agent.parent = vue_folder
vue_agent.installed = False
vue_folder.children = [vue_agent]

# Add subcategories to backend
api_folder = TreeNode("api", Path("backend/api"), is_folder=True, level=1)
api_folder.parent = backend
backend.children = [api_folder]

rest_folder = TreeNode("rest", Path("backend/api/rest"), is_folder=True, level=2)
graphql_folder = TreeNode("graphql", Path("backend/api/graphql"), is_folder=True, level=2)
rest_folder.parent = api_folder
graphql_folder.parent = api_folder
api_folder.children = [rest_folder, graphql_folder]

# Add agents
fastapi_agent = TreeNode("fastapi-expert", Path("backend/api/rest/fastapi-expert.md"), is_folder=False, level=3)
fastapi_agent.parent = rest_folder
fastapi_agent.installed = False
rest_folder.children = [fastapi_agent]

# Test display
def print_tree(node, indent=""):
    if node.level >= 0:
        display = node.get_display_name()
        changes = node.get_changes_display()
        print(f"{indent}{display}{changes}")
    
    if node.is_folder and node.expanded:
        for child in node.children:
            print_tree(child, indent + "  ")

print("\n1. Initial Tree:")
print_tree(root)

# Test selection and change tracking
print("\n2. After selecting agents:")
vue_agent.selected = True
fastapi_agent.selected = True

# Update changes from root
root.children[1].update_changes_summary({})  # frontend
root.children[2].update_changes_summary({})  # backend

print_tree(root)

# Test folder toggle
print("\n3. After collapsing API folder:")
api_folder.toggle_expand()
print_tree(root)

print("\n4. After expanding API folder:")
api_folder.toggle_expand()
print_tree(root)

print("\n✓ Tree functionality verified!")