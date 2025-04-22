const { app, BrowserWindow } = require('electron');
const { spawn } = require('child_process');
const path = require('path');
const http = require('http');

function createWindow() {
  const win = new BrowserWindow({
    width: 1200,
    height: 900,
    show: false,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
    },
  });

  const checkServer = () => {
    console.log("Checking Shiny server...");
    http.get('http://localhost:3000', (res) => {
      console.log("Connected to Shiny.");
      win.loadURL('http://localhost:3000').then(() => {
        console.log("Showing app window...");
        win.show();
      });
    }).on('error', (err) => {
      console.log("Shiny not ready yet, retrying...");
      setTimeout(checkServer, 500);
    });
  };

  checkServer();
}

app.whenReady().then(() => {
  const rScript = process.platform === 'win32' ? 'run-r.bat' : './run-r.sh';

  console.log(`Spawning R process with script: ${rScript}`);

  const r = spawn(rScript, [], {
    cwd: app.getAppPath(),
    shell: true,
    stdio: 'inherit' // log output directly to terminal for visibility
  });

  r.on('error', (err) => {
    console.error("Error launching R process:", err);
  });

  r.on('exit', (code) => {
    console.log(`R process exited with code ${code}`);
  });

  createWindow();
});

app.on('window-all-closed', () => {
  app.quit();
});