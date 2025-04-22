#!/bin/bash

# Kill anything using port 3000
PID=$(lsof -ti:3000)
if [ -n "$PID" ]; then
  kill -9 $PID
fi

# --- Launch the app ---
Rscript -e "shiny::runApp('shiny', launch.browser=FALSE, port=3000)" > shiny_log.txt 2>&1