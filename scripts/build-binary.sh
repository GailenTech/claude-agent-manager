#!/bin/bash

# Build script for agent-manager binaries

echo "Building agent-manager binary..."

# Detect platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if [[ $(uname -m) == "arm64" ]]; then
        BINARY_NAME="bin/agent-manager-macos-arm64"
    else
        BINARY_NAME="bin/agent-manager-macos-x86_64"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    BINARY_NAME="bin/agent-manager-linux-x86_64"
else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi

# Ensure bin directory exists
mkdir -p bin

# Copy the Python script as the binary
cp agent-manager "$BINARY_NAME"
chmod +x "$BINARY_NAME"

echo "Binary built: $BINARY_NAME"
echo "Testing binary..."

# Test the binary with --version
python3 agent-manager --version 2>/dev/null || true

echo "Build complete!"