#!/bin/bash

# Kill anything using port 3000
PID=$(lsof -ti:3000)
if [ -n "$PID" ]; then
  kill -9 $PID
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if we're in the packaged app (resources directory) or development
if [[ "$SCRIPT_DIR" == *"/Resources" ]]; then
  # We're in the packaged app
  SHINY_DIR="$SCRIPT_DIR/shiny"
else
  # We're in development
  SHINY_DIR="$SCRIPT_DIR/shiny"
fi

echo "Starting Shiny app from: $SHINY_DIR"

# --- Launch the app ---
Rscript -e "shiny::runApp('$SHINY_DIR', launch.browser=FALSE, port=3000)" > "$SCRIPT_DIR/shiny_log.txt" 2>&1