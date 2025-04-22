🚀 Welcome to SandBoxML
=======================

This application requires R and several R libraries to function.

The setup process is designed to run automatically the first time 
you launch the application. However, if setup fails, follow the 
instructions below to manually install R and the required packages.

-----------------------------------------
🔧 Step 1: Install R (if not already installed)
-----------------------------------------
Visit the official CRAN website and download the latest version of R:
https://cran.r-project.org

Be sure to follow installation instructions for your operating system.

-----------------------------------------
📦 Step 2: Launch R and install dependencies
-----------------------------------------
1. Open the R application (not RStudio).
2. In the R console, paste and run the following command:

install.packages(c(
  "shiny", "cluster", "factoextra", "dplyr", "shinyFiles", "ggplot2", "fs",
  "DT", "markdown", "naniar", "missRanger", "readr", "gridExtra", "rlang",
  "randomForest", "caret", "pROC", "shinyjs"
))

3. After all packages have installed successfully, restart SandBoxML.

-----------------------------------------
💡 Tips:
-----------------------------------------
- Ensure you are connected to the internet during setup.
- You need to have administrator privileges to install the application.
- If the app fails to launch, please ensure run-r.sh has execute permission:
	chmod +x run-r.sh

Thank you for using SandboxML!