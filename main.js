const { app, BrowserWindow, dialog } = require('electron');
const { spawn } = require('child_process');
const path = require('path');
const http = require('http');
const fs = require('fs');

let rProcess = null;
let mainWindow = null;
let serverCheckTimeout = null;

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
  } else {
    dialog.showErrorBox('SandboxML Error', message);
    app.quit();
  }
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
    
    if (process.platform === 'win32') {
      // On Windows, we need to kill the process tree
      spawn('taskkill', ['/pid', rProcess.pid, '/f', '/t']);
    } else {
      // On macOS/Linux, we can kill the process directly
      rProcess.kill('SIGTERM');
    }
    
    rProcess = null;
  }
  
  // Clear any pending server checks
  if (serverCheckTimeout) {
    clearTimeout(serverCheckTimeout);
    serverCheckTimeout = null;
  }
}

app.whenReady().then(() => {
  if (startRProcess()) {
    createWindow();
  } else {
    showError("Failed to start R process. The application will now quit.");
    app.quit();
  }
});

app.on('window-all-closed', () => {
  stopRProcess();
  app.quit();
});

app.on('will-quit', () => {
  stopRProcess();
});

// Handle macOS app activation
app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});