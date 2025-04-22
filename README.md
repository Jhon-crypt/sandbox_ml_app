# SandboxML

SandboxML is a machine learning application built with R's Shiny framework and packaged with Electron to provide a desktop application experience. The application offers data analysis tools focusing on three key areas: Missing Data management, Clustering, and Random Forest modeling.

## Features

- **Missing Data Handling**: Tools for visualizing and handling missing data in your datasets
- **Clustering**: Implementations of clustering algorithms with visualization tools
- **Random Forest**: Powerful Random Forest implementation for classification and prediction

## System Requirements

- Operating System: Windows, macOS, or Linux
- R (version 4.0.0 or higher recommended)
- Node.js and npm (for Electron)

## Installation

### 1. Install R

First, ensure R is installed on your system:

- **Windows/macOS/Linux**: Download and install R from [CRAN](https://cran.r-project.org/)

### 2. Install Required R Packages

Open R and run the following command to install all necessary packages:

```r
install.packages(c(
  "shiny", "cluster", "factoextra", "dplyr", "shinyFiles", "ggplot2", "fs",
  "DT", "markdown", "naniar", "missRanger", "readr", "gridExtra", "rlang",
  "randomForest", "caret", "pROC", "shinyjs"
))
```

### 3. Install Node Dependencies

In the root directory of the project, run:

```bash
npm install
```

## Running the Application

### Important Note for Packaged Application

When running the packaged SandboxML application (DMG or ZIP), you need to ensure:

1. **R is installed** on your system (download from [CRAN](https://cran.r-project.org/))
2. **Required R packages are installed** using one of the following methods:

#### Method 1: Using the Installer Script (Recommended)

1. After installing SandboxML, open Terminal
2. Navigate to the Resources folder inside the application:
   ```bash
   cd /Applications/SandboxML.app/Contents/Resources
   ```
3. Run the installer script:
   ```bash
   ./install_dependencies.sh
   ```
4. Once the dependencies are installed, you can use SandboxML

#### Method 2: Manual Installation

Open R and install the required packages:
```r
install.packages(c(
  "shiny", "cluster", "factoextra", "dplyr", "shinyFiles", "ggplot2", "fs",
  "DT", "markdown", "naniar", "missRanger", "readr", "gridExtra", "rlang",
  "randomForest", "caret", "pROC", "shinyjs"
))
```

### Troubleshooting Path Issues

If you encounter an error about `R not found` or the app exits with code 127:

1. Make sure R is installed
2. Add R to your PATH environment variable
3. Run the dependency installer script as described above

### Option 1: Using npm

From the project root directory, run:

```bash
npm start
```

This will launch the Electron application which will automatically start the R Shiny server in the background.

### Option 2: Running the Shiny App Directly

If you only want to run the Shiny application without Electron:

```bash
R -e "shiny::runApp('shiny', launch.browser=TRUE, port=3000)"
```

Then access the application in your web browser at http://localhost:3000

## Troubleshooting

### Execution Permissions

If you're on macOS or Linux, you may need to make the run-r.sh script executable:

```bash
chmod +x run-r.sh
```

### Port Conflicts

If port 3000 is already in use, you can change the port in both:
- `run-r.sh` (or `run-r.bat` for Windows)
- `main.js` (update the port in the URL)

### Missing Packages

If you encounter errors about missing packages, you can install them individually:

```r
install.packages("package_name")
```

### Application Crash or Freeze

1. Check the `shiny_log.txt` file for error messages
2. Ensure all R packages are up to date
3. Restart your computer and try again

## Project Structure

- `/shiny`: Contains the R Shiny application
  - `app.R`: Main entry point for the Shiny app
  - `shinyMiss_v3.R`: Missing data handling module
  - `shinyK_v2.R`: Clustering module
  - `shinyRF_v3.R`: Random Forest module
  - `*.Rmd`: Help documentation in R Markdown format
- `main.js`: Electron main process
- `run-r.sh`/`run-r.bat`: Scripts to launch the R Shiny server

## Stopping the Application

To stop the application:

- Close the Electron window
- Or terminate the process using Task Manager (Windows), Activity Monitor (macOS), or `pkill -f electron` (Linux/macOS)

## Credits

SandboxML was developed by Shelli Kesler (Version 1.0).

## License

See the LICENSE file for details. 