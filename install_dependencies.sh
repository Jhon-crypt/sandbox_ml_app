#!/bin/bash

echo "==============================================="
echo "SandboxML Dependency Installer"
echo "==============================================="
echo ""

# Use SANDBOXML_R_PATH if available, otherwise default to system R
if [ -n "$SANDBOXML_R_PATH" ]; then
    echo "Using R from SANDBOXML_R_PATH: $SANDBOXML_R_PATH"
    R_CMD="$SANDBOXML_R_PATH"
    
    # If path is to Rscript, convert to R for consistency
    if [[ "$SANDBOXML_R_PATH" == *"Rscript"* ]]; then
        R_CMD="${SANDBOXML_R_PATH%script}"
    fi
    
    # Extract R_HOME from R path
    R_HOME=$(dirname "$(dirname "$R_CMD")")
    RSCRIPT_CMD="${R_CMD}script"
else
    R_CMD="R"
    RSCRIPT_CMD="Rscript"
fi

echo "Using R command: $R_CMD"
echo "Using Rscript command: $RSCRIPT_CMD"

# Check if R is installed
if command -v "$R_CMD" >/dev/null 2>&1; then
    R_VERSION=$("$R_CMD" --version | head -n 1)
    echo "✓ $R_VERSION is installed."
else
    echo "✗ R is not installed or not found at $R_CMD."
    echo ""
    
    # Try common locations
    for R_LOCATION in "/Library/Frameworks/R.framework/Resources/bin/R" "/usr/local/bin/R" "/usr/bin/R" "/opt/homebrew/bin/R"
    do
        if [ -f "$R_LOCATION" ]; then
            echo "Found R at $R_LOCATION"
            R_CMD="$R_LOCATION"
            RSCRIPT_CMD="${R_CMD}script"
            R_VERSION=$("$R_CMD" --version | head -n 1)
            echo "✓ $R_VERSION is installed."
            break
        fi
    done
    
    # If still not found
    if ! command -v "$R_CMD" >/dev/null 2>&1; then
        echo "Please install R from https://cran.r-project.org/bin/macosx/"
        echo "After installing R, run this script again."
        exit 1
    fi
fi

# Check if Rscript is available
if command -v "$RSCRIPT_CMD" >/dev/null 2>&1; then
    echo "✓ Rscript is available at $RSCRIPT_CMD"
else
    echo "✗ Rscript is not found at $RSCRIPT_CMD"
    echo "Adding R to PATH for this session..."
    
    # Try to find R installation
    if [ -n "$R_HOME" ]; then
        export PATH="$R_HOME/bin:$PATH"
    else
        R_HOME="/Library/Frameworks/R.framework/Resources"
        export PATH="$R_HOME/bin:$PATH"
    fi
    
    # Check again
    if command -v Rscript >/dev/null 2>&1; then
        echo "✓ Rscript is now available"
        RSCRIPT_CMD="Rscript"
    else
        echo "✗ Failed to add Rscript to PATH"
        echo "Please make sure R is installed correctly."
        exit 1
    fi
fi

echo ""
echo "Installing required R packages..."
echo "This may take several minutes."
echo ""

# Install all required packages, using the specific R/Rscript found
"$RSCRIPT_CMD" - <<EOF
required_packages <- c(
  "shiny", "cluster", "factoextra", "dplyr", "shinyFiles", "ggplot2", "fs",
  "DT", "markdown", "naniar", "missRanger", "readr", "gridExtra", "rlang",
  "randomForest", "caret", "pROC", "shinyjs"
)

# Function to check package installation
check_and_install <- function(packages) {
  installed <- installed.packages()[, "Package"]
  to_install <- packages[!packages %in% installed]
  
  if (length(to_install) > 0) {
    cat("Installing packages:", paste(to_install, collapse=", "), "\n")
    install.packages(to_install, repos="https://cloud.r-project.org")
  } else {
    cat("All packages already installed\n")
  }
  
  # Verify all were installed
  installed <- installed.packages()[, "Package"]
  not_installed <- packages[!packages %in% installed]
  
  if (length(not_installed) > 0) {
    cat("FAILED to install:", paste(not_installed, collapse=", "), "\n")
    return(FALSE)
  } else {
    cat("All packages successfully installed or already available\n")
    return(TRUE)
  }
}

# Try to install the packages
success <- check_and_install(required_packages)
if (!success) {
  cat("\nSome packages could not be installed.\n")
  cat("This might be due to network issues or package dependencies.\n")
  quit(status = 1)
}

cat("\nAll dependencies installed successfully!\n")
EOF

# Check the exit code from the R script
if [ $? -eq 0 ]; then
    echo ""
    echo "==============================================="
    echo "✓ All dependencies installed successfully!"
    echo "You can now run SandboxML."
    echo "==============================================="
else
    echo ""
    echo "==============================================="
    echo "✗ There was a problem installing some dependencies."
    echo "Please try running this script again or install"
    echo "the packages manually within R."
    echo "==============================================="
    exit 1
fi 