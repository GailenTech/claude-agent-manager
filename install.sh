#!/bin/bash

# Claude Agent Manager - Installer
# This script installs the agent-manager tool and makes it available system-wide

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="/usr/local/bin"
AGENT_COLLECTION_DIR="/usr/local/share/claude-agents"
CONFIG_DIR="$HOME/.config/claude-agent-manager"

echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║          Claude Agent Manager - Installation Script           ║${NC}"
echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo

# Check for Python 3
echo -n "Checking Python 3... "
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    echo -e "${GREEN}✓${NC} Found Python $PYTHON_VERSION"
else
    echo -e "${RED}✗${NC}"
    echo -e "${RED}Error: Python 3 is required but not found.${NC}"
    echo "Please install Python 3 and try again."
    exit 1
fi

# Check for curses module
echo -n "Checking Python curses module... "
if python3 -c "import curses" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "Installing curses module may be required."
fi

# Check for sudo access if needed
if [[ ! -w "$INSTALL_DIR" ]]; then
    echo -e "\n${YELLOW}Installation requires administrator privileges.${NC}"
    echo "You may be prompted for your password."
    SUDO="sudo"
else
    SUDO=""
fi

# Installation options
echo -e "\n${BOLD}Installation Options:${NC}"
echo "1) System-wide installation (recommended)"
echo "2) User-only installation (~/.local/bin)"
echo "3) Custom location"
echo
read -p "Select option [1-3]: " install_option

case "$install_option" in
    1)
        INSTALL_DIR="/usr/local/bin"
        AGENT_COLLECTION_DIR="/usr/local/share/claude-agents"
        if [[ ! -w "$INSTALL_DIR" ]]; then
            SUDO="sudo"
        fi
        ;;
    2)
        INSTALL_DIR="$HOME/.local/bin"
        AGENT_COLLECTION_DIR="$HOME/.local/share/claude-agents"
        SUDO=""
        mkdir -p "$INSTALL_DIR"
        ;;
    3)
        read -p "Enter installation directory: " INSTALL_DIR
        INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"
        AGENT_COLLECTION_DIR="$INSTALL_DIR/claude-agents"
        SUDO=""
        mkdir -p "$INSTALL_DIR"
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

echo -e "\n${BOLD}Installation Summary:${NC}"
echo "  Install location: $INSTALL_DIR/agent-manager"
echo "  Agent collection: $AGENT_COLLECTION_DIR"
echo "  Configuration:    $CONFIG_DIR"
echo

read -p "Proceed with installation? [y/N]: " confirm
if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Create directories
echo -e "\n${CYAN}Creating directories...${NC}"
$SUDO mkdir -p "$AGENT_COLLECTION_DIR"
mkdir -p "$CONFIG_DIR"

# Copy agent collection
echo -e "${CYAN}Installing agent collection...${NC}"
for category in platform frontend backend infrastructure; do
    if [[ -d "$SCRIPT_DIR/agents-collection/$category" ]]; then
        $SUDO mkdir -p "$AGENT_COLLECTION_DIR/$category"
        $SUDO cp -r "$SCRIPT_DIR/agents-collection/$category"/*.md "$AGENT_COLLECTION_DIR/$category/" 2>/dev/null || true
        echo -e "  ${GREEN}✓${NC} $category agents"
    fi
done

# Create wrapper script that knows where agents are
echo -e "${CYAN}Creating agent-manager executable...${NC}"
cat > /tmp/agent-manager << 'EOF'
#!/usr/bin/env python3
import sys
import os

# Set the agent collection path
os.environ['CLAUDE_AGENT_COLLECTION'] = 'AGENT_COLLECTION_PATH'

# Run the actual script
exec(open('SCRIPT_PATH').read())
EOF

# Replace placeholders
sed -i.bak "s|AGENT_COLLECTION_PATH|$AGENT_COLLECTION_DIR|g" /tmp/agent-manager
sed -i.bak "s|SCRIPT_PATH|$SCRIPT_DIR/agent-manager|g" /tmp/agent-manager
rm /tmp/agent-manager.bak

# Install the wrapper
$SUDO install -m 755 /tmp/agent-manager "$INSTALL_DIR/agent-manager"
rm /tmp/agent-manager

# Update the main script to use the environment variable
echo -e "${CYAN}Configuring agent-manager...${NC}"
cp "$SCRIPT_DIR/agent-manager" "$CONFIG_DIR/agent-manager.py"

# Patch the script to use the environment variable
sed -i.bak 's|self.agents_collection = self.script_dir / "agents-collection"|self.agents_collection = Path(os.environ.get("CLAUDE_AGENT_COLLECTION", self.script_dir / "agents-collection"))|' "$CONFIG_DIR/agent-manager.py"

# Create the final executable
cat > /tmp/agent-manager-final << EOF
#!/usr/bin/env python3
import sys
import os
from pathlib import Path

# Set the agent collection path
os.environ['CLAUDE_AGENT_COLLECTION'] = '$AGENT_COLLECTION_DIR'

# Run the actual script
with open('$CONFIG_DIR/agent-manager.py', 'r') as f:
    code = f.read()
    exec(code)
EOF

$SUDO install -m 755 /tmp/agent-manager-final "$INSTALL_DIR/agent-manager"
rm /tmp/agent-manager-final

# Add to PATH if needed
if [[ "$install_option" == "2" ]]; then
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo -e "\n${YELLOW}Note: Add the following to your shell configuration:${NC}"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
        
        # Try to add it automatically
        if [[ -f "$HOME/.bashrc" ]]; then
            echo -e "\n${CYAN}Adding to ~/.bashrc...${NC}"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        fi
        if [[ -f "$HOME/.zshrc" ]]; then
            echo -e "${CYAN}Adding to ~/.zshrc...${NC}"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
        fi
    fi
fi

# Success message
echo -e "\n${BOLD}${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║                    Installation Complete! ✓                   ║${NC}"
echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${BOLD}Usage:${NC}"
echo "  agent-manager         - Launch the agent manager"
echo
echo -e "${BOLD}First time setup:${NC}"
echo "  1. Run 'agent-manager' to open the interface"
echo "  2. Press '1' for General view (user-wide agents)"
echo "  3. Press '2' for Project view (project-specific agents)"
echo "  4. Select agents with SPACE and save with 's'"
echo
echo -e "${BOLD}Installed components:${NC}"
echo -e "  • Executable: ${GREEN}$INSTALL_DIR/agent-manager${NC}"
echo -e "  • Agents:     ${GREEN}$AGENT_COLLECTION_DIR${NC}"
echo -e "  • Config:     ${GREEN}$CONFIG_DIR${NC}"

# Test if it's in PATH
if command -v agent-manager &> /dev/null; then
    echo -e "\n${GREEN}✓ agent-manager is now available in your PATH${NC}"
else
    echo -e "\n${YELLOW}⚠ Restart your terminal or run: source ~/.bashrc${NC}"
fi