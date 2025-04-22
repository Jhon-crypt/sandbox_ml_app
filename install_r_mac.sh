#!/bin/bash

# SandboxML R Installer
# This script downloads and installs the latest version of R for macOS

echo "======================================================"
echo "  SandboxML - R Installer for macOS"
echo "======================================================"
echo ""

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check if we have curl or wget
if command_exists curl; then
  DOWNLOADER="curl -L -o"
elif command_exists wget; then
  DOWNLOADER="wget -O"
else
  echo "Error: This script requires either curl or wget."
  echo "Please install one of these tools and try again."
  exit 1
fi

# Get latest R version from CRAN
if command_exists curl; then
  R_URL=$(curl -s https://cran.r-project.org/bin/macosx/ | grep -o 'href="[^"]*\.pkg"' | head -1 | sed 's/href="/https:\/\/cran.r-project.org\/bin\/macosx\//g' | sed 's/"//g')
elif command_exists wget; then
  R_URL=$(wget -qO- https://cran.r-project.org/bin/macosx/ | grep -o 'href="[^"]*\.pkg"' | head -1 | sed 's/href="/https:\/\/cran.r-project.org\/bin\/macosx\//g' | sed 's/"//g')
fi

if [ -z "$R_URL" ]; then
  echo "Error: Could not determine the latest R version."
  echo "Please visit https://cran.r-project.org/bin/macosx/ to download R manually."
  exit 1
fi

R_VERSION=$(echo $R_URL | grep -o 'R-[0-9.]*' | head -1)
DOWNLOAD_PATH="$HOME/Downloads/$R_VERSION.pkg"

echo "Downloading $R_VERSION from CRAN..."
echo "URL: $R_URL"
echo "This may take a few minutes depending on your internet connection."
echo ""

# Download the R installer
$DOWNLOADER "$DOWNLOAD_PATH" "$R_URL"

if [ $? -ne 0 ]; then
  echo "Error: Download failed."
  echo "Please visit https://cran.r-project.org/bin/macosx/ to download R manually."
  exit 1
fi

echo "Download complete: $DOWNLOAD_PATH"
echo ""
echo "Opening the R installer. Please follow the installation prompts."
echo ""

# Open the installer
open "$DOWNLOAD_PATH"

echo "Once R is installed, please restart SandboxML."
echo "The application will automatically install all required R packages."
echo "" 