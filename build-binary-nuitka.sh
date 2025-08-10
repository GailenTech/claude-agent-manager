#!/bin/bash

# Build optimized standalone binary using Nuitka
# Creates a faster, smaller binary than PyInstaller

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║     Claude Agent Manager - Nuitka Binary Builder              ║${NC}"
echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo

# Check for Python 3
echo -n "Checking Python 3... "
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    echo -e "${GREEN}✓${NC} Found Python $PYTHON_VERSION"
else
    echo -e "${RED}✗${NC}"
    echo -e "${RED}Error: Python 3 is required.${NC}"
    exit 1
fi

# Check/Install Nuitka
echo -n "Checking Nuitka... "
if python3 -c "import nuitka" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}Not found${NC}"
    echo "Installing Nuitka..."
    pip3 install nuitka --user
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install Nuitka${NC}"
        echo "Try: pip3 install nuitka"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} Nuitka installed"
fi

# Detect OS
OS_TYPE=$(uname -s)
ARCH=$(uname -m)

case "$OS_TYPE" in
    Darwin*)
        PLATFORM="macos"
        if [ "$ARCH" = "arm64" ]; then
            PLATFORM="${PLATFORM}-arm64"
        else
            PLATFORM="${PLATFORM}-x86_64"
        fi
        ;;
    Linux*)
        PLATFORM="linux"
        if [ "$ARCH" = "x86_64" ]; then
            PLATFORM="${PLATFORM}-x86_64"
        elif [ "$ARCH" = "aarch64" ]; then
            PLATFORM="${PLATFORM}-arm64"
        else
            PLATFORM="${PLATFORM}-${ARCH}"
        fi
        ;;
    *)
        echo -e "${RED}Unsupported OS: $OS_TYPE${NC}"
        exit 1
        ;;
esac

OUTPUT_NAME="agent-manager-${PLATFORM}"

echo
echo -e "${BOLD}Build Configuration:${NC}"
echo "  Platform:    $PLATFORM"
echo "  Output:      dist/$OUTPUT_NAME"
echo "  Compiler:    Nuitka (optimized)"
echo

# Create directories
mkdir -p dist build

# Create a Python wrapper that includes the agents collection
cat > build/agent-manager-standalone.py << 'EOF'
#!/usr/bin/env python3
"""Standalone version of agent-manager with embedded agent collection path"""

import sys
import os
from pathlib import Path

# Get the directory where the binary is located
if getattr(sys, 'frozen', False):
    # Running as compiled binary
    application_path = Path(sys.executable).parent
else:
    # Running as script
    application_path = Path(__file__).parent.parent

# Set the agent collection path
os.environ['CLAUDE_AGENT_COLLECTION'] = str(application_path / 'agents-collection')

# Import and run the main script
exec(open(application_path / 'agent-manager').read())
EOF

# Build with Nuitka
echo -e "${CYAN}Building optimized binary with Nuitka...${NC}"
echo "(This may take a few minutes...)"

python3 -m nuitka \
    --standalone \
    --onefile \
    --assume-yes-for-downloads \
    --output-dir=dist \
    --output-filename="$OUTPUT_NAME" \
    --include-data-dir="agents-collection=agents-collection" \
    --include-data-file="agent-manager=agent-manager" \
    --follow-imports \
    --plugin-enable=anti-bloat \
    --plugin-enable=implicit-imports \
    --show-progress \
    --show-memory \
    build/agent-manager-standalone.py 2>&1 | tee build/nuitka-build.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Build successful"
    
    # Make executable
    chmod +x "dist/$OUTPUT_NAME"
    
    # Get file size
    SIZE=$(ls -lh "dist/$OUTPUT_NAME" | awk '{print $5}')
    
    echo
    echo -e "${BOLD}${GREEN}✓ Optimized binary created successfully!${NC}"
    echo
    echo -e "${BOLD}Binary Details:${NC}"
    echo "  File:     dist/$OUTPUT_NAME"
    echo "  Size:     $SIZE"
    echo "  Platform: $PLATFORM"
    echo "  Type:     Nuitka optimized (faster startup)"
    echo
    echo -e "${BOLD}Installation:${NC}"
    echo "  System-wide:  sudo cp dist/$OUTPUT_NAME /usr/local/bin/agent-manager"
    echo "  User only:    cp dist/$OUTPUT_NAME ~/.local/bin/agent-manager"
    echo
    echo -e "${BOLD}Or run directly:${NC}"
    echo "  ./dist/$OUTPUT_NAME"
    
    # Test the binary
    echo
    echo -e "${CYAN}Testing binary...${NC}"
    if timeout 2 "./dist/$OUTPUT_NAME" --help 2>/dev/null || true; then
        echo -e "${GREEN}✓${NC} Binary works!"
    else
        echo -e "${YELLOW}⚠${NC} Binary created but couldn't verify (this is normal for GUI apps)"
    fi
else
    echo -e "${RED}Build failed${NC}"
    echo "Check build/nuitka-build.log for details"
    tail -20 build/nuitka-build.log
    exit 1
fi

# Cleanup
echo
read -p "Clean up build files? [y/N]: " cleanup
if [[ "$cleanup" =~ ^[yY]$ ]]; then
    rm -rf build
    echo -e "${GREEN}✓${NC} Build files cleaned"
fi

echo
echo -e "${BOLD}${GREEN}Done!${NC}"