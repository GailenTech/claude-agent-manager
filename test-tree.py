#!/usr/bin/env python3
"""Test the tree structure functionality without curses"""

import sys
import os
from pathlib import Path

# Import the classes directly from the script
exec(open('agent-manager-tree.py').read(), globals())

def test_tree_structure():
    """Test tree building and change tracking"""
    manager = AgentManagerTree()
    
    print("Tree Structure Test")
    print("=" * 50)
    
    # Test tree building
    print("\n1. Tree Building:")
    def print_tree(node, indent=""):
        if node.level >= 0:
            display = node.get_display_name()
            changes = node.get_changes_display()
            print(f"{indent}{display}{changes}")
        
        if node.is_folder and node.expanded:
            for child in node.children:
                print_tree(child, indent + "  ")
    
    print_tree(manager.tree_root)
    
    # Test flattening
    print("\n2. Flattened View:")
    manager.flatten_tree()
    for i, node in enumerate(manager.flattened_nodes[:10]):
        if node.is_folder:
            print(f"{i}: [FOLDER] {node.name} (level {node.level})")
        else:
            print(f"{i}: [AGENT] {node.name} (level {node.level})")
    
    # Test selection and change tracking
    print("\n3. Selection & Change Tracking:")
    
    # Find an agent to select
    test_agent = None
    for node in manager.flattened_nodes:
        if not node.is_folder:
            test_agent = node
            break
    
    if test_agent:
        print(f"Selecting agent: {test_agent.name}")
        manager.toggle_selection(test_agent)
        
        # Update changes summary
        manager.update_all_changes_summary()
        
        # Print changes for parent folders
        parent = test_agent.parent
        while parent and parent.level >= 0:
            changes = parent.get_changes_display()
            if changes:
                print(f"  {parent.name}: {changes}")
            parent = parent.parent
    
    # Test folder expansion toggle
    print("\n4. Folder Toggle Test:")
    for node in manager.tree_root.children[:2]:
        if node.is_folder:
            print(f"Folder: {node.name}")
            print(f"  Before: expanded={node.expanded}")
            node.toggle_expand()
            print(f"  After: expanded={node.expanded}")
    
    print("\n✓ All tests completed successfully!")

if __name__ == "__main__":
    test_tree_structure()