#!/bin/bash

# Output debug information
echo "Starting run-r.sh script"
echo "Current directory: $(pwd)"
echo "Script location: $0"

# Function to cleanup on exit
cleanup() {
  echo "Cleaning up processes..."
  
  # Kill any process using port 3000
  PID=$(lsof -ti:3000)
  if [ -n "$PID" ]; then
    echo "Killing process using port 3000: $PID"
    kill -9 $PID || true
  fi
  
  # Kill any R processes started by this script
  if [ -n "$R_PID" ]; then
    echo "Killing R process: $R_PID"
    kill -9 $R_PID || true
  fi
  
  echo "Cleanup complete"
}

# Set the cleanup function to run on script exit
trap cleanup EXIT INT TERM

# Kill anything using port 3000
PID=$(lsof -ti:3000)
if [ -n "$PID" ]; then
  echo "Killing process using port 3000: $PID"
  kill -9 $PID
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Script directory: $SCRIPT_DIR"

# Check if SANDBOXML_R_PATH is set and use it if available
if [ -n "$SANDBOXML_R_PATH" ]; then
  echo "Using R from environment variable: $SANDBOXML_R_PATH"
  
  if [[ "$SANDBOXML_R_PATH" == *"Rscript"* ]]; then
    # If the path points to Rscript, use it directly
    RSCRIPT="$SANDBOXML_R_PATH"
    # Extract R_HOME from Rscript path
    R_HOME=$(dirname "$(dirname "$SANDBOXML_R_PATH")")
  elif [[ "$SANDBOXML_R_PATH" == *"/R" ]]; then
    # If the path points to R, derive Rscript from it
    RSCRIPT="${SANDBOXML_R_PATH}script"
    # Extract R_HOME from R path
    R_HOME=$(dirname "$(dirname "$SANDBOXML_R_PATH")")
  else
    # Default case - just use the provided path and assume Rscript is nearby
    RSCRIPT="$SANDBOXML_R_PATH"
    # Try to find R_HOME
    R_HOME=$(dirname "$(dirname "$SANDBOXML_R_PATH")")
  fi
else
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
fi

# Always set SHINY_DIR to be in the script directory
SHINY_DIR="$SCRIPT_DIR/shiny"

echo "Using Shiny app from: $SHINY_DIR"
echo "Using R_HOME: $R_HOME"
echo "Using Rscript: $RSCRIPT"

# Check if Rscript exists
if [ ! -f "$RSCRIPT" ]; then
  echo "Rscript not found at $RSCRIPT"
  
  # Try to find Rscript in common locations
  for R_LOCATION in "/Library/Frameworks/R.framework/Resources/bin/Rscript" "/usr/local/bin/Rscript" "/usr/bin/Rscript" "/opt/homebrew/bin/Rscript"
  do
    if [ -f "$R_LOCATION" ]; then
      echo "Found alternative Rscript at $R_LOCATION"
      RSCRIPT="$R_LOCATION"
      R_HOME=$(dirname "$(dirname "$RSCRIPT")")
      break
    fi
  done
  
  # If still not found, try which command
  if [ ! -f "$RSCRIPT" ]; then
    RSCRIPT=$(which Rscript 2>/dev/null)
    if [ -n "$RSCRIPT" ]; then
      echo "Found Rscript using which: $RSCRIPT"
      R_HOME=$(dirname "$(dirname "$RSCRIPT")")
    else
      # Last resort: try running Rscript directly
      if command -v Rscript >/dev/null 2>&1; then
        RSCRIPT="Rscript"
        echo "Using Rscript from PATH"
      else
        echo "Error: Rscript not found at $RSCRIPT and not in PATH"
        exit 1
      fi
    fi
  fi
fi

# Add R to the PATH
export PATH="$R_HOME/bin:$PATH"
export R_HOME="$R_HOME"

# Print PATH for debugging
echo "PATH: $PATH"

# --- Launch the app ---
echo "Launching Shiny app..."
"$RSCRIPT" -e "shiny::runApp('$SHINY_DIR', launch.browser=FALSE, port=3000)" > "$SCRIPT_DIR/shiny_log.txt" 2>&1 &
R_PID=$!

# Wait for R process to finish
wait $R_PID

# Check exit code
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "R process exited with code $EXIT_CODE"
  cat "$SCRIPT_DIR/shiny_log.txt"
  exit $EXIT_CODE
fi