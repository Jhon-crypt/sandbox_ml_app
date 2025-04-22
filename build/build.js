#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const { checkRInstallation, checkRPackages } = require('./checkR');

// Create build directory if it doesn't exist
if (!fs.existsSync(path.join(__dirname, '..', 'build', 'temp'))) {
  fs.mkdirSync(path.join(__dirname, '..', 'build', 'temp'), { recursive: true });
}

// Check if R and required packages are installed
if (!checkRInstallation() || !checkRPackages()) {
  console.error('Build preparation failed: R environment check failed');
  process.exit(1);
}

// Install electron-builder if not already installed
try {
  console.log('Installing build dependencies...');
  execSync('npm install --save-dev electron-builder electron-notarize', {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit'
  });
} catch (error) {
  console.error('Failed to install build dependencies:', error);
  process.exit(1);
}

// Check if the run-r.sh script is executable
const runRshPath = path.join(__dirname, '..', 'run-r.sh');
try {
  const stats = fs.statSync(runRshPath);
  if (!(stats.mode & 0o111)) {
    console.log('Making run-r.sh executable...');
    fs.chmodSync(runRshPath, '755');
  }
} catch (error) {
  console.error('Error checking run-r.sh permissions:', error);
}

// Choose the correct build command based on platform
let buildCommand = '';
const platform = process.platform;

if (platform === 'darwin') {
  buildCommand = 'electron-builder --mac';
} else if (platform === 'win32') {
  buildCommand = 'electron-builder --win';
} else if (platform === 'linux') {
  buildCommand = 'electron-builder --linux';
} else {
  console.error(`Unsupported platform: ${platform}`);
  process.exit(1);
}

// Run the build command
console.log(`Building SandboxML for ${platform}...`);
try {
  execSync(buildCommand, {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit',
    env: {
      ...process.env,
      SKIP_NOTARIZE: 'true'  // Skip notarization by default
    }
  });
  console.log('Build completed successfully!');
} catch (error) {
  console.error('Build failed:', error);
  process.exit(1);
} 