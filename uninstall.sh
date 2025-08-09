#!/bin/bash

# Claude Agent Manager - Uninstaller

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║         Claude Agent Manager - Uninstall Script               ║${NC}"
echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo

# Common installation locations
LOCATIONS=(
    "/usr/local/bin/agent-manager"
    "$HOME/.local/bin/agent-manager"
    "/usr/local/share/claude-agents"
    "$HOME/.local/share/claude-agents"
    "$HOME/.config/claude-agent-manager"
)

echo -e "${BOLD}This will remove:${NC}"
for location in "${LOCATIONS[@]}"; do
    if [[ -e "$location" ]]; then
        echo -e "  ${YELLOW}•${NC} $location"
    fi
done

echo -e "\n${YELLOW}Note: Your installed agents in ~/.claude/agents will NOT be removed.${NC}"
echo

read -p "Continue with uninstallation? [y/N]: " confirm
if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

# Remove files
echo -e "\n${CYAN}Removing agent-manager...${NC}"

# Remove executables
for exe in "/usr/local/bin/agent-manager" "$HOME/.local/bin/agent-manager"; do
    if [[ -f "$exe" ]]; then
        if [[ -w "$(dirname "$exe")" ]]; then
            rm -f "$exe"
            echo -e "  ${GREEN}✓${NC} Removed $exe"
        else
            sudo rm -f "$exe"
            echo -e "  ${GREEN}✓${NC} Removed $exe (with sudo)"
        fi
    fi
done

# Remove agent collections
for dir in "/usr/local/share/claude-agents" "$HOME/.local/share/claude-agents"; do
    if [[ -d "$dir" ]]; then
        if [[ -w "$(dirname "$dir")" ]]; then
            rm -rf "$dir"
            echo -e "  ${GREEN}✓${NC} Removed $dir"
        else
            sudo rm -rf "$dir"
            echo -e "  ${GREEN}✓${NC} Removed $dir (with sudo)"
        fi
    fi
done

# Remove config directory
if [[ -d "$HOME/.config/claude-agent-manager" ]]; then
    rm -rf "$HOME/.config/claude-agent-manager"
    echo -e "  ${GREEN}✓${NC} Removed configuration directory"
fi

echo -e "\n${BOLD}${GREEN}✓ Uninstallation complete${NC}"
echo -e "\n${DIM}Your installed agents in ~/.claude/agents were preserved.${NC}"
echo -e "${DIM}To remove them, manually delete ~/.claude/agents if desired.${NC}"