#!/bin/bash

echo "==============================================="
echo "SandboxML Dependency Installer"
echo "==============================================="
echo ""

# Check if R is installed
if command -v R >/dev/null 2>&1; then
    R_VERSION=$(R --version | head -n 1)
    echo "✓ $R_VERSION is installed."
else
    echo "✗ R is not installed."
    echo ""
    echo "Please install R from https://cran.r-project.org/bin/macosx/"
    echo "After installing R, run this script again."
    exit 1
fi

# Check if Rscript is in PATH
if command -v Rscript >/dev/null 2>&1; then
    echo "✓ Rscript is in PATH"
else
    echo "✗ Rscript is not in PATH"
    echo "Adding R to PATH for this session..."
    
    # Try to find R installation
    R_HOME="/Library/Frameworks/R.framework/Resources"
    export PATH="$R_HOME/bin:$PATH"
    
    # Check again
    if command -v Rscript >/dev/null 2>&1; then
        echo "✓ Rscript is now available"
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

# Install all required packages
Rscript - <<EOF
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