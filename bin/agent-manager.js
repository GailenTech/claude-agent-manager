#\!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

function getBinaryName() {
  const platform = os.platform();
  const arch = os.arch();
  
  if (platform === 'darwin') {
    return arch === 'arm64' ? 'agent-manager-macos-arm64' : 'agent-manager-macos-x86_64';
  } else if (platform === 'linux') {
    return 'agent-manager-linux-x86_64';
  } else {
    console.error(`Unsupported platform: ${platform}`);
    process.exit(1);
  }
}

function findBinary() {
  const binaryName = getBinaryName();
  
  // Try multiple locations
  const possiblePaths = [
    path.join(__dirname, binaryName),
    path.join(__dirname, '..', 'bin', binaryName),
    path.join(process.cwd(), 'bin', binaryName)
  ];
  
  for (const binaryPath of possiblePaths) {
    if (fs.existsSync(binaryPath)) {
      return binaryPath;
    }
  }
  
  return null;
}

function main() {
  const binaryPath = findBinary();
  
  if (\!binaryPath) {
    console.error('Claude Agent Manager binary not found.');
    console.error('The installation may have failed.');
    console.error('');
    console.error('Try reinstalling:');
    console.error('  npm uninstall -g claude-code-agent-manager');
    console.error('  npm install -g claude-code-agent-manager');
    console.error('');
    console.error('Or install from GitHub directly:');
    console.error('  curl -fsSL https://raw.githubusercontent.com/GailenTech/claude-agent-manager/main/install.sh | sh');
    process.exit(1);
  }
  
  // Make sure binary is executable
  try {
    fs.chmodSync(binaryPath, '755');
  } catch (error) {
    // Ignore chmod errors
  }
  
  // Spawn the binary with all arguments
  const child = spawn(binaryPath, process.argv.slice(2), {
    stdio: 'inherit',
    detached: false
  });
  
  child.on('error', (error) => {
    if (error.code === 'ENOENT') {
      console.error('Error: Binary not found at', binaryPath);
    } else {
      console.error('Error running agent-manager:', error.message);
    }
    process.exit(1);
  });
  
  child.on('exit', (code, signal) => {
    if (signal) {
      process.exit(128 + 15); // Default signal value
    } else {
      process.exit(code || 0);
    }
  });
}

main();
