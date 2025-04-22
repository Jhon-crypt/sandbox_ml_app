const { app, BrowserWindow, dialog } = require('electron');
const { spawn, execSync } = require('child_process');
const path = require('path');
const http = require('http');
const fs = require('fs');

let rProcess = null;
let mainWindow = null;
let serverCheckTimeout = null;
let installInProgress = false;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 900,
    show: false,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
    },
    icon: path.join(__dirname, 'icons', process.platform === 'win32' ? 'win/icon.ico' : 'png/512x512.png')
  });

  // Check if Shiny server is running
  const checkServer = () => {
    console.log("Checking Shiny server...");
    http.get('http://localhost:3000', (res) => {
      console.log("Connected to Shiny server on port 3000");
      mainWindow.loadURL('http://localhost:3000').then(() => {
        console.log("Showing app window...");
        mainWindow.show();
        clearTimeout(serverCheckTimeout);
      }).catch(err => {
        console.error("Error loading Shiny app:", err);
        showError("Failed to load Shiny application. Please check the logs.");
      });
    }).on('error', (err) => {
      console.log("Shiny not ready yet, retrying...");
      serverCheckTimeout = setTimeout(checkServer, 1000);
    });
  };

  checkServer();
  
  mainWindow.on('closed', () => {
    mainWindow = null;
    stopRProcess();
  });
}

function showError(message) {
  if (mainWindow) {
    dialog.showErrorBox('SandboxML Error', message);
    
    // After showing an error, ensure we clean up properly
    setTimeout(() => {
      stopRProcess();
      app.exit(1); // Force exit with error code
    }, 5000); // Give user 5 seconds to read the error before force quitting
  } else {
    dialog.showErrorBox('SandboxML Error', message);
    app.quit();
  }
}

function openRDownloadPage() {
  const platform = process.platform;
  
  if (platform === 'darwin') {
    // Use our custom installer script for macOS
    const installerPath = path.join(process.resourcesPath, 'install_r_mac.sh');
    
    // Make sure it's executable
    try {
      fs.chmodSync(installerPath, '755');
      
      // Launch the installer script
      const installer = spawn(installerPath, [], {
        detached: true,
        stdio: 'ignore'
      });
      
      installer.unref();
      console.log("Launched R installer script");
      return;
    } catch (err) {
      console.error("Error launching R installer script:", err);
      // Fall back to opening the website if script fails
    }
  }
  
  // Default fallback to opening the website
  let downloadUrl = 'https://cran.r-project.org/';
  
  if (platform === 'darwin') {
    downloadUrl = 'https://cran.r-project.org/bin/macosx/';
  } else if (platform === 'win32') {
    downloadUrl = 'https://cran.r-project.org/bin/windows/base/';
  } else if (platform === 'linux') {
    downloadUrl = 'https://cran.r-project.org/bin/linux/';
  }
  
  require('electron').shell.openExternal(downloadUrl);
}

async function showRInstallDialog() {
  return new Promise((resolve) => {
    const dialogOptions = {
      type: 'question',
      buttons: ['Download R', 'Quit'],
      defaultId: 0,
      title: 'SandboxML - R Installation Required',
      message: 'R is required but not found on your system',
      detail: 'SandboxML requires R to run. Would you like to open the R download page in your browser?'
    };
    
    dialog.showMessageBox(null, dialogOptions).then(result => {
      if (result.response === 0) {
        // Download R button clicked
        openRDownloadPage();
        resolve(false); // Return false as R isn't installed yet
      } else {
        // Quit button clicked
        resolve(false);
      }
    });
  });
}

async function checkAndInstallDependencies() {
  return new Promise((resolve, reject) => {
    // Skip in development mode
    if (!app.isPackaged) {
      console.log("Development mode: skipping automatic dependency installation");
      return resolve(true);
    }
    
    console.log("Checking R installation and dependencies...");
    
    // Determine the path to the installer script
    const basePath = process.resourcesPath;
    const installerPath = path.join(basePath, 'install_dependencies.sh');
    
    // Check if installer exists
    if (!fs.existsSync(installerPath)) {
      console.error(`Installer script not found at ${installerPath}`);
      return resolve(false);
    }
    
    // Make sure it's executable
    try {
      fs.chmodSync(installerPath, '755');
    } catch (err) {
      console.error("Error making installer script executable:", err);
    }
    
    // Check if R is installed
    try {
      execSync('which R');
      console.log("R is installed.");
      
      // Run a simple R command to check if it works
      execSync('R --version');
      console.log("R is working.");
      
      // Check if dependencies are installed
      const checkScript = `
      required_packages <- c(
        "shiny", "cluster", "factoextra", "dplyr", "shinyFiles", "ggplot2", "fs",
        "DT", "markdown", "naniar", "missRanger", "readr", "gridExtra", "rlang",
        "randomForest", "caret", "pROC", "shinyjs"
      )
      installed <- installed.packages()[, "Package"]
      missing <- required_packages[!required_packages %in% installed]
      cat(length(missing))
      `;
      
      const output = execSync(`R --vanilla -e "${checkScript}"`).toString().trim();
      const missingCount = parseInt(output);
      
      if (missingCount === 0) {
        console.log("All dependencies are already installed.");
        return resolve(true);
      }
      
      console.log(`Found ${missingCount} missing dependencies. Installing...`);
      
      // Set the install dialog
      installInProgress = true;
      const installWindow = new BrowserWindow({
        width: 500,
        height: 300,
        show: true,
        alwaysOnTop: true,
        webPreferences: {
          nodeIntegration: true,
          contextIsolation: false,
        }
      });
      
      // Create a simple HTML progress page
      const progressHtml = `
        <html>
        <head>
          <style>
            body {
              font-family: system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
              margin: 20px;
              text-align: center;
              background-color: #f5f5f7;
              color: #1d1d1f;
            }
            h2 {
              margin-top: 30px;
              font-weight: 500;
            }
            .loader {
              margin: 40px auto;
              border: 5px solid #f3f3f3;
              border-radius: 50%;
              border-top: 5px solid #0066cc;
              width: 50px;
              height: 50px;
              animation: spin 1s linear infinite;
            }
            @keyframes spin {
              0% { transform: rotate(0deg); }
              100% { transform: rotate(360deg); }
            }
            p {
              margin-top: 30px;
              font-size: 14px;
              color: #666;
            }
          </style>
        </head>
        <body>
          <h2>Installing SandboxML Dependencies</h2>
          <div class="loader"></div>
          <p>This may take a few minutes.<br>The application will start automatically when installation completes.</p>
        </body>
        </html>
      `;
      
      const progressPath = path.join(app.getPath('temp'), 'progress.html');
      fs.writeFileSync(progressPath, progressHtml);
      installWindow.loadFile(progressPath);
      
      // Run the installer
      const installer = spawn(installerPath, [], {
        shell: true,
        stdio: 'pipe'
      });
      
      let stdout = '';
      let stderr = '';
      
      installer.stdout.on('data', (data) => {
        stdout += data.toString();
        console.log(`INSTALLER: ${data.toString().trim()}`);
      });
      
      installer.stderr.on('data', (data) => {
        stderr += data.toString();
        console.error(`INSTALLER ERROR: ${data.toString().trim()}`);
      });
      
      installer.on('error', (err) => {
        console.error("Error running installer:", err);
        installInProgress = false;
        installWindow.close();
        reject(err);
      });
      
      installer.on('exit', (code) => {
        installInProgress = false;
        installWindow.close();
        
        if (code === 0) {
          console.log("Dependencies installed successfully.");
          resolve(true);
        } else {
          console.error(`Installer exited with code ${code}`);
          const errorMsg = stderr || stdout || "Unknown error during installation";
          showError(`Failed to install dependencies. Please install manually using the instructions in the README.\n\nError: ${errorMsg}`);
          resolve(false);
        }
      });
      
    } catch (err) {
      console.error("Error checking R installation:", err);
      // Instead of showing an error directly, show a dialog offering to download R
      resolve('no-r'); // Special response to indicate R is not installed
    }
  });
}

function startRProcess() {
  // Get the correct path to the R script
  const isPackaged = app.isPackaged;
  
  // Use resourcesPath for packaged app, appPath for development
  const basePath = isPackaged ? process.resourcesPath : app.getAppPath();
  
  // Choose the appropriate script based on platform
  const scriptName = process.platform === 'win32' ? 'run-r.bat' : 'run-r.sh';
  const scriptPath = path.join(basePath, scriptName);
  
  console.log(`Starting R process with script: ${scriptPath}`);
  console.log(`Current directory: ${basePath}`);
  console.log(`App is packaged: ${isPackaged}`);
  
  // Check if the script exists
  if (!fs.existsSync(scriptPath)) {
    console.error(`Script not found: ${scriptPath}`);
    showError(`Cannot find R script at ${scriptPath}`);
    return false;
  }
  
  // Make sure the script is executable on macOS/Linux
  if (process.platform !== 'win32') {
    try {
      fs.chmodSync(scriptPath, '755');
    } catch (err) {
      console.error(`Error making script executable: ${err}`);
    }
  }
  
  // Check for R installation
  if (process.platform === 'darwin') {
    const rFrameworkPath = '/Library/Frameworks/R.framework';
    if (!fs.existsSync(rFrameworkPath)) {
      console.error('R Framework not found on the system');
      showError('R is not installed on this system. Please install R from https://cran.r-project.org/bin/macosx/');
      return false;
    }
  }
  
  // Spawn the R process
  try {
    rProcess = spawn(scriptPath, [], {
      cwd: basePath, // Use the same base path for current working directory
      shell: true,
      stdio: 'inherit' // log output directly to terminal for visibility
    });
    
    rProcess.on('error', (err) => {
      console.error("Error launching R process:", err);
      showError(`Failed to start R: ${err.message}`);
    });
    
    rProcess.on('exit', (code) => {
      console.log(`R process exited with code ${code}`);
      if (code !== 0 && mainWindow) {
        if (code === 127) {
          showError(`R process exited with code ${code} (command not found). Make sure R is installed and in the PATH.`);
        } else {
          // Try to read the log file
          let logMessage = "Check shiny_log.txt for details.";
          const logPath = path.join(basePath, "shiny_log.txt");
          if (fs.existsSync(logPath)) {
            try {
              const log = fs.readFileSync(logPath, 'utf8');
              if (log) {
                logMessage = log.substring(0, 500) + (log.length > 500 ? "... (truncated)" : "");
              }
            } catch (err) {
              console.error("Error reading log file:", err);
            }
          }
          showError(`R process exited with code ${code}.\n\n${logMessage}`);
        }
      }
      rProcess = null;
    });
    
    return true;
  } catch (err) {
    console.error("Failed to spawn R process:", err);
    showError(`Failed to start R: ${err.message}`);
    return false;
  }
}

function stopRProcess() {
  if (rProcess) {
    console.log("Stopping R process...");
    
    // Kill any process using port 3000 (Shiny)
    try {
      if (process.platform === 'win32') {
        // On Windows, we need to kill the process tree
        spawn('taskkill', ['/pid', rProcess.pid, '/f', '/t']);
        // Also try to kill any process on port 3000
        spawn('cmd', ['/c', 'for /f "tokens=5" %p in (\'netstat -aon ^| findstr :3000\') do taskkill /F /PID %p']);
      } else {
        // On macOS/Linux, we can kill the process directly
        rProcess.kill('SIGTERM');
        // Also kill any process on port 3000
        spawn('bash', ['-c', 'lsof -ti:3000 | xargs kill -9 || true']);
      }
    } catch (err) {
      console.error("Error killing R process:", err);
    }
    
    rProcess = null;
  }
  
  // Clear any pending server checks
  if (serverCheckTimeout) {
    clearTimeout(serverCheckTimeout);
    serverCheckTimeout = null;
  }
}

app.whenReady().then(async () => {
  // Check and install dependencies first
  const dependenciesOk = await checkAndInstallDependencies();
  
  if (dependenciesOk === 'no-r') {
    // R is not installed, show dialog offering to download
    console.log("R is not installed. Showing download dialog...");
    await showRInstallDialog();
    app.quit();
  } else if (dependenciesOk && startRProcess()) {
    createWindow();
  } else if (!dependenciesOk) {
    showError("Failed to install dependencies. Please install manually using the instructions in the README.");
    app.quit();
  } else {
    showError("Failed to start R process. The application will now quit.");
    app.quit();
  }
});

app.on('window-all-closed', () => {
  stopRProcess();
  app.quit();
});

app.on('before-quit', () => {
  console.log("Application is quitting...");
  stopRProcess();
});

// Add a stronger quit handler for when app is force-quit
process.on('SIGTERM', () => {
  console.log("Received SIGTERM signal");
  stopRProcess();
  app.quit();
});

process.on('SIGINT', () => {
  console.log("Received SIGINT signal");
  stopRProcess();
  app.quit();
});

// Handle macOS app activation
app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0 && !installInProgress) {
    createWindow();
  }
});