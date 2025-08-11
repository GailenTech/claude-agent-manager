#!/usr/bin/env node

const https = require('https');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { pipeline } = require('stream');
const { promisify } = require('util');

const streamPipeline = promisify(pipeline);

function getBinaryInfo() {
  const platform = os.platform();
  const arch = os.arch();
  
  if (platform === 'darwin') {
    if (arch === 'arm64') {
      return {
        name: 'agent-manager-macos-arm64',
        url: 'https://github.com/GailenTech/claude-agent-manager/releases/latest/download/agent-manager-macos-arm64.tar.gz'
      };
    } else {
      return {
        name: 'agent-manager-macos-x86_64',
        url: 'https://github.com/GailenTech/claude-agent-manager/releases/latest/download/agent-manager-macos-x86_64.tar.gz'
      };
    }
  } else if (platform === 'linux') {
    return {
      name: 'agent-manager-linux-x86_64',
      url: 'https://github.com/GailenTech/claude-agent-manager/releases/latest/download/agent-manager-linux-x86_64.tar.gz'
    };
  } else {
    throw new Error(`Unsupported platform: ${platform}`);
  }
}

async function downloadAndExtract() {
  try {
    const binaryInfo = getBinaryInfo();
    const binDir = path.join(__dirname, '..', 'bin');
    const binaryPath = path.join(binDir, binaryInfo.name);
    
    // Skip if binary already exists
    if (fs.existsSync(binaryPath)) {
      console.log('Binary already exists, skipping download');
      return;
    }
    
    console.log(`Downloading ${binaryInfo.name} from GitHub releases...`);
    
    // Create temp file
    const tempFile = path.join(os.tmpdir(), 'agent-manager.tar.gz');
    
    // Download the file
    await new Promise((resolve, reject) => {
      const request = https.get(binaryInfo.url, (response) => {
        if (response.statusCode === 302 || response.statusCode === 301) {
          // Handle redirect
          https.get(response.headers.location, (redirectResponse) => {
            const fileStream = fs.createWriteStream(tempFile);
            streamPipeline(redirectResponse, fileStream).then(resolve).catch(reject);
          }).on('error', reject);
        } else if (response.statusCode === 200) {
          const fileStream = fs.createWriteStream(tempFile);
          streamPipeline(response, fileStream).then(resolve).catch(reject);
        } else {
          reject(new Error(`Download failed with status ${response.statusCode}`));
        }
      });
      
      request.on('error', reject);
      request.setTimeout(30000, () => {
        request.destroy();
        reject(new Error('Download timeout'));
      });
    });
    
    // Extract tar.gz directly to bin directory
    console.log('Extracting binary...');
    const { execSync } = require('child_process');
    
    try {
      // Ensure bin directory exists
      fs.mkdirSync(binDir, { recursive: true });
      
      // Extract the tar.gz directly to bin directory
      execSync(`tar -xzf ${tempFile} -C ${binDir}`, { stdio: 'inherit' });
      
      // The extracted file should be in binDir now
      // Check if it needs to be renamed or if it's already correct
      const extractedPath = path.join(binDir, binaryInfo.name);
      
      if (!fs.existsSync(extractedPath)) {
        // Maybe it extracted with a different name, try to find it
        const files = fs.readdirSync(binDir);
        const agentManagerFile = files.find(f => f.startsWith('agent-manager'));
        
        if (agentManagerFile && agentManagerFile !== binaryInfo.name) {
          // Rename to expected name
          const oldPath = path.join(binDir, agentManagerFile);
          fs.renameSync(oldPath, extractedPath);
        } else if (!agentManagerFile) {
          throw new Error(`Binary not found after extraction. Files in bin/: ${files.join(', ')}`);
        }
      }
      
      // Clean up temp file
      fs.unlinkSync(tempFile);
      
      // Make binary executable
      fs.chmodSync(extractedPath, '755');
    } catch (error) {
      // Clean up on error
      if (fs.existsSync(tempFile)) fs.unlinkSync(tempFile);
      throw error;
    }
    
    console.log('✓ Claude Agent Manager installed successfully!');
    console.log('Run: npx agent-manager');
    
  } catch (error) {
    console.error('Installation failed:', error.message);
    console.error('');
    console.error('Manual installation:');
    console.error('1. Download binary from: https://github.com/GailenTech/claude-agent-manager/releases');
    console.error('2. Extract and place in your PATH');
    process.exit(1);
  }
}

// Only run if called directly
if (require.main === module) {
  downloadAndExtract();
}

module.exports = { downloadAndExtract };