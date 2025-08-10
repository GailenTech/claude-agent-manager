#!/bin/bash

# Build standalone binary for Claude Agent Manager
# This creates a single executable file that doesn't require Python to be installed

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
echo -e "${BOLD}${BLUE}║         Claude Agent Manager - Binary Builder                 ║${NC}"
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

# Check/Install PyInstaller
echo -n "Checking PyInstaller... "
if python3 -c "import PyInstaller" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}Not found${NC}"
    echo "Installing PyInstaller..."
    pip3 install pyinstaller --user
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install PyInstaller${NC}"
        echo "Try: pip3 install pyinstaller"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} PyInstaller installed"
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
echo

# Create build directory
mkdir -p build dist

# Create a spec file for PyInstaller with proper configuration
cat > build/agent-manager.spec << 'EOF'
# -*- mode: python ; coding: utf-8 -*-

a = Analysis(
    ['../agent-manager'],
    pathex=[],
    binaries=[],
    datas=[
        ('../agents-collection', 'agents-collection'),
    ],
    hiddenimports=[
        'curses',
        '_curses',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
)

pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='OUTPUT_NAME',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=None,
)
EOF

# Replace output name in spec
sed -i.bak "s/OUTPUT_NAME/$OUTPUT_NAME/g" build/agent-manager.spec
rm build/agent-manager.spec.bak

# Build the binary
echo -e "${CYAN}Building binary...${NC}"
echo "(This may take a minute...)"

cd build
if pyinstaller agent-manager.spec --clean --noconfirm > build.log 2>&1; then
    echo -e "${GREEN}✓${NC} Build successful"
    
    # Move to dist directory
    if [ -f "dist/$OUTPUT_NAME" ]; then
        mv "dist/$OUTPUT_NAME" "../dist/$OUTPUT_NAME"
        cd ..
        
        # Make executable
        chmod +x "dist/$OUTPUT_NAME"
        
        # Get file size
        SIZE=$(ls -lh "dist/$OUTPUT_NAME" | awk '{print $5}')
        
        echo
        echo -e "${BOLD}${GREEN}✓ Binary created successfully!${NC}"
        echo
        echo -e "${BOLD}Binary Details:${NC}"
        echo "  File:     dist/$OUTPUT_NAME"
        echo "  Size:     $SIZE"
        echo "  Platform: $PLATFORM"
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
        if "./dist/$OUTPUT_NAME" --version 2>/dev/null || true; then
            echo -e "${GREEN}✓${NC} Binary works!"
        else
            echo -e "${YELLOW}⚠${NC} Binary created but couldn't verify (this is normal for GUI apps)"
        fi
    else
        echo -e "${RED}Build failed - binary not found${NC}"
        echo "Check build/build.log for details"
        exit 1
    fi
else
    cd ..
    echo -e "${RED}Build failed${NC}"
    echo "Check build/build.log for details"
    tail -20 build/build.log
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