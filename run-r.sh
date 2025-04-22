#!/bin/bash

# Output debug information
echo "Starting run-r.sh script"
echo "Current directory: $(pwd)"
echo "Script location: $0"

# Kill anything using port 3000
PID=$(lsof -ti:3000)
if [ -n "$PID" ]; then
  echo "Killing process using port 3000: $PID"
  kill -9 $PID
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Script directory: $SCRIPT_DIR"

# Check if we're in the packaged app (resources directory) or development
if [[ "$SCRIPT_DIR" == *"/Resources" ]]; then
  # We're in the packaged app
  SHINY_DIR="$SCRIPT_DIR/shiny"
  # In packaged app, use the bundled R framework if available
  if [ -d "$SCRIPT_DIR/../Frameworks/R.framework" ]; then
    R_HOME="$SCRIPT_DIR/../Frameworks/R.framework/Resources"
    RSCRIPT="$SCRIPT_DIR/../Frameworks/R.framework/Resources/bin/Rscript"
  else
    # Fall back to system R
    R_HOME="/Library/Frameworks/R.framework/Resources"
    RSCRIPT="/Library/Frameworks/R.framework/Resources/bin/Rscript"
  fi
else
  # We're in development
  SHINY_DIR="$SCRIPT_DIR/shiny"
  R_HOME="/Library/Frameworks/R.framework/Resources"
  RSCRIPT="/Library/Frameworks/R.framework/Resources/bin/Rscript"
fi

echo "Using Shiny app from: $SHINY_DIR"
echo "Using R_HOME: $R_HOME"
echo "Using Rscript: $RSCRIPT"

# Check if Rscript exists
if [ ! -f "$RSCRIPT" ]; then
  echo "Error: Rscript not found at $RSCRIPT"
  exit 1
fi

# Add R to the PATH
export PATH="$R_HOME/bin:$PATH"
export R_HOME="$R_HOME"

# --- Launch the app ---
echo "Launching Shiny app..."
"$RSCRIPT" -e "shiny::runApp('$SHINY_DIR', launch.browser=FALSE, port=3000)" > "$SCRIPT_DIR/shiny_log.txt" 2>&1

# Check exit code
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "R process exited with code $EXIT_CODE"
  cat "$SCRIPT_DIR/shiny_log.txt"
  exit $EXIT_CODE
fi