# Master Shiny ML App

# Install and load required packages
required_packages <- c(
  "shiny", "cluster", "factoextra", "dplyr", "shinyFiles", "ggplot2", "fs",
  "DT", "markdown", "naniar", "missRanger", "readr", "gridExtra", "rlang",
  "randomForest", "caret", "pROC", "shinyjs"
)

new_packages <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]
if (length(new_packages)) install.packages(new_packages)

invisible(lapply(required_packages, library, character.only = TRUE))

source("shinyMiss_v3.R")
source("shinyK_v2.R")
source("shinyRF_v3.R")

rm(list = ls())

ui <- navbarPage("Sandbox ML",
                 header = tags$h4(
                   "Shelli Kesler – Version 1.0",
                   style = "margin-top: -10px; margin-left: 12px; color: gray; font-weight: normal;"
                 ),
                 
                 tabPanel("Missing Data", miss_app$ui),
                 tabPanel("Clustering", clust_app$ui),
                 tabPanel("Random Forest", rf_app$ui)
)

server <- function(input, output, session) {
  miss_app$server(input, output, session)
  clust_app$server(input, output, session)
  rf_app$server(input, output, session)
}

shinyApp(ui, server)