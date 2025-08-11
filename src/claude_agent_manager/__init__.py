"""Claude Agent Manager - Terminal-based agent manager for Claude Code."""

__version__ = "1.0.0"
__author__ = "GailenTech"

def main():
    """Entry point for the CLI tool."""
    import os
    import sys
    
    # Get the directory where this package is installed
    package_dir = os.path.dirname(__file__)
    
    # Look for agent-manager script in package directory or project root
    agent_manager_paths = [
        os.path.join(package_dir, 'agent-manager'),
        os.path.join(package_dir, '..', '..', 'agent-manager'),
        'agent-manager'  # fallback to current directory
    ]
    
    agent_manager_script = None
    for path in agent_manager_paths:
        if os.path.exists(path):
            agent_manager_script = path
            break
    
    if not agent_manager_script:
        print("Error: agent-manager script not found")
        sys.exit(1)
    
    # Execute the agent-manager script
    with open(agent_manager_script, 'r') as f:
        script_content = f.read()
    
    # Set up the environment
    old_argv = sys.argv
    try:
        sys.argv = ['agent-manager'] + sys.argv[1:]
        exec(script_content, {'__name__': '__main__'})
    finally:
        sys.argv = old_argv

if __name__ == "__main__":
    main()