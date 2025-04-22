# SandboxML

SandboxML is a machine learning application built with R's Shiny framework and packaged with Electron to provide a desktop application experience. The application offers data analysis tools focusing on three key areas: Missing Data management, Clustering, and Random Forest modeling.

## Features

- **Missing Data Handling**: Tools for visualizing and handling missing data in your datasets
- **Clustering**: Implementations of K-means and K-medoids clustering algorithms with visualization tools
- **Random Forest**: Powerful Random Forest implementation for classification and regression with performance metrics and visualizations

## System Requirements

- Operating System: Windows 10/11 or macOS 10.15+ (Catalina or newer)
- R (version 4.0.0 or higher required)
- Node.js and npm (for development and packaging)

## Installation & Setup

### For End Users (Using Pre-packaged Application)

#### macOS Installation

1. Download the SandboxML.dmg file
2. Open the DMG file and drag SandboxML to your Applications folder
3. **Important**: When first launching, right-click (or Ctrl+click) on the app and select "Open" to bypass Gatekeeper
4. If R is not installed, the app will prompt you to install it or guide you to download it from [CRAN](https://cran.r-project.org/)
5. The app will automatically install required R packages on first run

#### Windows Installation

1. Download the SandboxML-Setup.exe file
2. Run the installer and follow the prompts
3. If R is not installed, the app will prompt you to install it or guide you to download it from [CRAN](https://cran.r-project.org/)
4. The app will automatically install required R packages on first run

### For Developers (Building from Source)

#### 1. Install Dependencies

First, ensure you have the necessary tools:

- R (install from [CRAN](https://cran.r-project.org/))
- Node.js & npm (install from [nodejs.org](https://nodejs.org/))
- Git (for cloning the repository)

#### 2. Clone the Repository

```bash
git clone https://github.com/yourusername/sandboxml.git
cd sandboxml
```

#### 3. Install Node Dependencies

```bash
npm install
```

#### 4. Install Required R Packages

Open R and run:

```r
install.packages(c(
  "shiny", "cluster", "factoextra", "dplyr", "shinyFiles", "ggplot2", "fs",
  "DT", "markdown", "naniar", "missRanger", "readr", "gridExtra", "rlang",
  "randomForest", "caret", "pROC", "shinyjs"
))
```

Alternatively, run the included script:

```bash
# On macOS/Linux:
chmod +x install_dependencies.sh
./install_dependencies.sh

# On Windows:
.\install_dependencies.sh
```

## Running the Application

### For End Users

Simply launch the installed application:

- **macOS**: Open SandboxML from your Applications folder
- **Windows**: Open SandboxML from the Start Menu or desktop shortcut

### For Developers

From the project root directory:

```bash
npm start
```

This launches the Electron application, which automatically starts the R Shiny server in the background.

## Usage Guide

1. **Missing Data Tab**
   - Upload your CSV data file
   - Visualize missing data patterns
   - Choose from different imputation methods
   - Export the cleaned dataset

2. **Clustering Tab**
   - Upload your pre-processed data
   - Choose clustering method (K-means or K-medoids)
   - Select automatic or manual k selection
   - Examine silhouette plots and cluster visualizations

3. **Random Forest Tab**
   - Upload your dataset
   - Select your outcome variable
   - Choose between classification and regression
   - Configure cross-validation and parameter selection
   - View variable importance and model performance metrics
   - Create plots to visualize results
   - Save the trained model for later use

## Troubleshooting

### Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| App does not start | Ensure R is installed and in PATH |
| Missing package errors | Run the installer script again or manually install packages |
| Port conflicts | Close other applications that might be using port 3000 |
| Plot not showing | Try running the model again; check console for errors |
| Data upload issues | Ensure your CSV file is properly formatted and has no special characters in headers |

### Log Files

Check these log files for troubleshooting:

- `shiny_log.txt`: Contains output from the R Shiny process

## Packaging for Distribution

### Packaging for macOS

1. Ensure you have all prerequisites installed
2. Set up environment variables for notarization (if publishing to App Store):
   ```bash
   export APPLE_ID=your.apple.id@example.com
   export APPLE_ID_PASSWORD=your-app-specific-password
   ```
3. Run the build command:
   ```bash
   # Without notarization:
   npm run dist:mac
   
   # With notarization:
   SKIP_NOTARIZE=false npm run dist:mac
   ```
4. Find the packaged app in the `dist` directory

### Packaging for Windows

1. Ensure you have all prerequisites installed
2. Run the build command:
   ```bash
   npm run dist:win
   ```
3. Find the installer and portable versions in the `dist` directory

### Universal Build Command

For convenience, build for your current platform:

```bash
npm run build
```

## Working with the Codebase

### Project Structure

- `/shiny`: Contains the R Shiny application
  - `app.R`: Main entry point for the Shiny app
  - `shinyMiss_v3.R`: Missing data handling module
  - `shinyK_v2.R`: Clustering module
  - `shinyRF_v3.R`: Random Forest module
  - `*.Rmd`: Help documentation in R Markdown format
- `main.js`: Electron main process script
- `run-r.sh`/`run-r.bat`: Platform-specific scripts to launch the R Shiny server
- `install_dependencies.sh`: Script to install required R packages
- `package.json`: Node.js project configuration

### Important Notes for Contributing

- When modifying the app, test both regression and classification models in the Random Forest module
- Ensure cross-platform compatibility by testing on both macOS and Windows
- Follow the code style and conventions in the existing modules
- Test thoroughly with different data types and formats

## Mac and Windows R Path Handling

### macOS

The app searches for R in these locations:
1. Custom path from `SANDBOXML_R_PATH` environment variable
2. Standard macOS R installation paths:
   - `/Library/Frameworks/R.framework/Resources/bin/Rscript`
   - `/usr/local/bin/Rscript`
   - `/usr/bin/Rscript`

### Windows

The app searches for R in these locations:
1. Custom path from `SANDBOXML_R_PATH` environment variable
2. Program Files directories:
   - `C:\Program Files\R\R-*\bin\Rscript.exe`
   - `C:\Program Files\R\R-*\bin\x64\Rscript.exe`

## Credits

SandboxML was developed by Shelli Kesler (Version 1.0).

## License

See the LICENSE file for details. 