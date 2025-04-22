@echo off

REM --- Check for R installation ---
where Rscript >nul 2>&1
if errorlevel 1 (
  echo R is not installed. Please install it from https://cran.r-project.org
  pause
  exit /b
)

REM --- Check if setup has already run ---
if not exist ".setup_done" (
  echo Running initial setup...
  Rscript setup.R
  if errorlevel 1 (
    echo Setup failed. Please check your internet connection or R installation.
    pause
    exit /b
  )
  echo Setup complete. > .setup_done
)

REM --- Launch the app ---
Rscript -e "shiny::runApp('shiny', launch.browser=FALSE, port=3000)"