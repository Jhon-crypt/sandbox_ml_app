# Packaging SandboxML for Distribution

This document provides instructions for packaging the SandboxML application for distribution on different platforms.

## Prerequisites

Before packaging, ensure you have:

1. Node.js and npm installed
2. R installed and accessible from PATH
3. All required R packages installed
4. For macOS code signing: An Apple Developer account

## Package for macOS

### Step 1: Check Requirements

Verify that R and all required packages are installed:

```bash
npm run check:r
```

### Step 2: Standard Packaging (without signing)

For testing purposes, you can build an unsigned version:

```bash
npm run dist:mac
```

The packaged application will be in the `dist` directory.

### Step 3: Code Signing and Notarization (for distribution)

1. Set up environment variables for notarization:

```bash
export APPLE_ID=your.apple.id@example.com
export APPLE_ID_PASSWORD=your-app-specific-password
```

2. Run the build script:

```bash
SKIP_NOTARIZE=false npm run dist:mac
```

This will:
- Sign the application with your developer certificate
- Notarize the application with Apple
- Create a .dmg file for distribution

### Important Notes for macOS

- The package includes the R framework from `/Library/Frameworks/R.framework`. Make sure R is installed on the build machine.
- The application requires "Hardened Runtime" entitlements for macOS security.
- The first time users run the app, they may need to right-click and select "Open" to bypass Gatekeeper.

## Package for Windows

### Step 1: Install Required Tools

```bash
npm install --save-dev electron-builder
```

### Step 2: Build the Package

```bash
npm run dist:win
```

### Windows-Specific Notes

- Ensure R is installed and in the PATH during development.
- The application uses run-r.bat to launch the R process.
- For full distribution, you may need to bundle R with your application or provide installation instructions.

## Using the Build Script

For convenience, a universal build script is provided that will automatically:

1. Check for R and required packages
2. Make run-r.sh executable (on macOS/Linux)
3. Build for the current platform

Run it with:

```bash
npm run build
```

## Customizing the Build

Edit the build configuration in `package.json` under the `build` key to customize:

- Application metadata
- Icons and branding
- File inclusions/exclusions
- Platform-specific options

## Troubleshooting

### R Not Found During Packaging

- Make sure R is installed and in the PATH
- Check the shiny_log.txt file after running for errors

### Missing R Packages

Install all required packages:

```r
install.packages(c(
  "shiny", "cluster", "factoextra", "dplyr", "shinyFiles", "ggplot2", "fs",
  "DT", "markdown", "naniar", "missRanger", "readr", "gridExtra", "rlang",
  "randomForest", "caret", "pROC", "shinyjs"
))
```

### Code Signing Issues

For macOS:
- Ensure you have a valid Developer ID certificate in your keychain
- Set the correct App-Specific Password in environment variables

## Distribution

After packaging:

1. Test the application thoroughly on the target platform
2. Create installation instructions for end-users
3. Consider providing a way to verify R is installed or install it automatically 