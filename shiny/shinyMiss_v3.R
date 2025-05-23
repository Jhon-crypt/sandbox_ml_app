# Shiny Missing Data App

miss_ui <- tagList(
  titlePanel("Missing Data Analysis"),
 
  sidebarLayout(
    sidebarPanel(
      helpText(tags$em("Data file should be cleaned.")),
      fileInput("miss_datafile", "Upload CSV File", accept = ".csv"),
    
      uiOutput("miss_outcome_select"),
      
      actionButton("plot_miss", "Plot Missing Data"),
      
      selectInput("miss_percent",
                  "Exclude variables with >?% missingness?",
                  choices = c("Don't exclude" = 0, 5, 10, 20),
                  selected = 10),
      
      radioButtons("miss_type", "Missing Imputation Strategy:",
                   choices = c("Listwise Deletion", "Single Stat", "Random Forest Imputation")),
      
      actionButton("impute_miss", "Impute Missing Data")
      
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Plot Missing Data",
                 tags$p("Tip: right click on a plot to save it.", 
                        style = "color: gray; font-style: italic; margin-top: 10px;"),
                 plotOutput("miss_plot"),
                 plotOutput("upset_plot"),
                 plotOutput("fct_plot"),
                 verbatimTextOutput("little_mcar")
                 
        ),
        
        tabPanel("Imputed Data",
                 tags$p("Tip: right click a plot to save it.", 
                        style = "color: gray; font-style: italic; margin-top: 10px;"),
                 plotOutput("imputed_observed"),
                 verbatimTextOutput("excluded_vars"),
                 shinySaveButton("save_imputed", "Save Imputed Data", "Save As...", filetype = list(csv = "csv"))
                 ),
        
        tabPanel("Data",
                 h4("Uploaded Dataset"),
                 DT::dataTableOutput("miss_dataView")
        ),
        
        tabPanel("Code",
                 h4("Missing Data Analysis Code"),
                 verbatimTextOutput("miss_codeOutput")
        ),
        
        tabPanel("Help",
                 h4(""),
                 uiOutput("miss_helpOutput")
        )

      )
    )
  )   
)

# Server
miss_server <- function(input, output, session) {
  df_imputed <- reactiveVal()
  volumes <- c(Home = fs::path_home(), shinyFiles::getVolumes()())
  shinyDirChoose(input, "miss_save_dir", roots = volumes, session = session)
  shinyFileSave(input, "save_imputed", roots = volumes, session = session)
  
  rf_save_path <- reactive({
    if (is.null(input$miss_save_dir)) return(NULL)
    parseDirPath(volumes, input$miss_save_dir)
  })
  
  miss_data <- reactive({
    req(input$miss_datafile)
    read_csv(input$miss_datafile$datapath,show_col_types = FALSE)
  })
  
  df_imputed <- reactiveVal(NULL)
  df_clean <- reactiveVal(NULL)
  
  
  output$miss_outcome_select <- renderUI({
    req(miss_data())
    selectInput("miss_outcome", "Select Grouping Variable for FCT Plot:", choices = names(miss_data()))
  })
  
  output$miss_dataView <- DT::renderDataTable({
    req(input$miss_datafile)
    df <- read.csv(input$miss_datafile$datapath)
    df
  })
  
  observeEvent(input$save_imputed, {
    req(df_imputed())
    
    fileinfo <- parseSavePath(volumes, input$save_imputed)
    if (nrow(fileinfo) > 0) {
      filepath <- as.character(fileinfo$datapath)
      if (!grepl("\\.csv$", filepath)) {
        filepath <- paste0(filepath, ".csv")
      }
      write_csv(df_imputed(), filepath)
    }
  })
  
  
  observeEvent(input$plot_miss, {
    
    df <- miss_data()
    outcome <- input$miss_outcome
    
    # Convert all binary variables to factors
    is_binary <- function(x) length(unique(na.omit(x))) == 2
    binary_vars <- sapply(df, is_binary)
    df[, binary_vars] <- lapply(df[, binary_vars, drop = FALSE], as.factor)
    
    output$miss_plot <- renderPlot({
      req(df,outcome)
      gg_miss_var(df) 
      
    })
    
    output$upset_plot <- renderPlot({
      req(df,outcome)
      gg_miss_upset(df) 
    })
    
    output$fct_plot <- renderPlot({
      req(df,outcome)
      if (!is.factor(df[[outcome]])) {
        # Show error message in place of plot
        plot.new()
        title("Silhouette Plot")
        text(0.5, 0.5,
             "Error: Grouping variable for FCT plot must be binary.",
             col = "red", cex = 1.1)
      } else {
        gg_miss_fct(x = df, fct = !!sym(input$miss_outcome))
      }
    })
    
    output$little_mcar <- renderPrint({
      req(df)
      if(is.numeric(df) == "TRUE") {
        littletest <- mcar_test(df)
        cat("Little's MCAR Test:\n")
        cat("Chi Sq:", littletest$statistic, "\n")
        cat("p value:", littletest$p.value, "\n")
      }
      else {
        cat("Little's MCAR test not valid for non-numeric data")
      }
    })
    
  })
 
  
  impute_single_stat <- function(df) {
    df_imputed <- df  # preserve original
    
    for (col in names(df)) {
      if (any(is.na(df[[col]]))) {
        # Numeric, not ordered
        if (is.numeric(df[[col]]) && !is.ordered(df[[col]])) {
          df_imputed[[col]][is.na(df[[col]])] <- mean(df[[col]], na.rm = TRUE)
          
          # Binary factor
        } else if (is.factor(df[[col]]) && nlevels(df[[col]]) == 2) {
          mode_val <- names(which.max(table(df[[col]])))
          df_imputed[[col]][is.na(df[[col]])] <- mode_val
          df_imputed[[col]] <- droplevels(df_imputed[[col]])
          
          # Ordered factor (ordinal)
        } else if (is.ordered(df[[col]])) {
          ord_vals <- as.integer(df[[col]])
          med_val <- median(ord_vals, na.rm = TRUE)
          levels_ord <- levels(df[[col]])
          df_imputed[[col]][is.na(df[[col]])] <- levels_ord[round(med_val)]
        }
      }
    }
    
    return(df_imputed)
  }
  
 # # Function for plots
 #  plot_imputed_observed <- function(df, df_imputed, miss_vars) {
 #    plots <- list()
 #    
 #    for (var in miss_vars) {
 #      # create a temporary dataframe with both imputed and observed info
 #      df_plot <- df %>%
 #        mutate(
 #          imputed = ifelse(is.na(.data[[var]]), "Imputed", "Observed"),
 #          value = coalesce(.data[[var]], df_imputed[[var]])
 #        )
 #      
 #      # Create and store the plot
 #      p <- ggplot(df_plot, aes(x = imputed, y = value, color = imputed)) +
 #        geom_point(position = position_jitter(width = 0.2, height = 0), alpha = 0.7, size = 1.5) +
 #        labs(title = var, x = NULL, y = NULL) +
 #        scale_color_manual(values = c("Imputed" = "#F8766D", "Observed" = "#00BFC4")) +
 #        scale_y_discrete() +
 #        theme_minimal()
 #      
 #      plots[[var]] <- p
 #    }
 #    
 #    return(plots)
 #  }
  
  plot_imputed_observed <- function(df, df_imputed, miss_vars) {
    plots <- list()
    
    for (var in miss_vars) {
      if (!var %in% names(df_imputed)) next
      if (all(is.na(df[[var]])) || all(is.na(df_imputed[[var]]))) next
      
      # Get indices of missing values in original df
      miss_idx <- which(is.na(df[[var]]))
      
      # Construct value vector
      value <- df[[var]]
      value[miss_idx] <- df_imputed[[var]][miss_idx]  # safely replace missing rows only
      
      # Create combined plot data
      df_plot <- data.frame(
        imputed = ifelse(is.na(df[[var]]), "Imputed", "Observed"),
        value = value
      )
      
      # Create and store the plot
      p <- ggplot(df_plot, aes(x = imputed, y = value, color = imputed)) +
        geom_point(position = position_jitter(width = 0.2, height = 0), alpha = 0.7, size = 1.5) +
        labs(title = var, x = NULL, y = NULL) +
        scale_color_manual(values = c("Imputed" = "#F8766D", "Observed" = "#00BFC4")) +
        scale_y_discrete() +
        theme_minimal()
      
      plots[[var]] <- p
    }
    
    return(plots)
  }
  
  observeEvent(input$impute_miss, {
    
    df <- miss_data()
    
    withProgress(message = "Imputing data", value = 0, {
      
      incProgress(0.5)
      
      # Convert all binary variables to factors
      is_binary <- function(x) length(unique(na.omit(x))) == 2
      binary_vars <- sapply(df, is_binary)
      df[, binary_vars] <- lapply(df[, binary_vars, drop = FALSE], as.factor)
      
      # Exclude high-missing variables if specified
      threshold <- as.numeric(input$miss_percent)
      percent_missing <- colSums(is.na(miss_data())) / nrow(miss_data()) * 100
      if (threshold != 0) {
         df <- df[, percent_missing <= threshold]
      }
      
      df_clean(df)
      
     imputed_result <- switch(input$miss_type,
                               "Listwise Deletion" = df[complete.cases(df), ],
                               "Single Stat" = impute_single_stat(df),
                               "Random Forest Imputation" = missRanger(df, num.trees = 100, verbose = 0, seed = 42)
      )
      
      df_imputed(imputed_result)
    
    
      incProgress(1, detail = "Done!")
    })
    
  debug_df <<- imputed_result
   
  }) # end observe impute 
  
  output$excluded_vars <- renderPrint({
    req(miss_data())
    
    percent_threshold <- suppressWarnings(as.numeric(input$miss_percent))
    req(!is.na(percent_threshold))
    
    percent_missing <- colSums(is.na(miss_data())) / nrow(miss_data()) * 100
    exc_vars <- names(percent_missing[percent_missing > percent_threshold])
    
    if (percent_threshold == 0) {
      cat("No variables were excluded (0% threshold selected).")
    } else if (length(exc_vars) > 0) {
      cat("Excluded variables due to high missingness (> ", percent_threshold, "%):\n", 
          paste(exc_vars, collapse = ", "))
    } else {
      cat("No variables exceeded the missingness threshold of", percent_threshold, "%.")
    }
  })
  
  output$imputed_observed <- renderPlot({
    req(df_imputed(),df_clean())
    
    output$imputed_download <- downloadHandler(
      filename = function() {
        "imputed_data.csv"
      },
      content = function(file) {
        write_csv(df_imputed(), file)
      }
    )
    
    miss_vars <- names(df_clean())[sapply(df_clean(), function(x) any(is.na(x)))]
    plots <- plot_imputed_observed(df_clean(), df_imputed(), miss_vars)
    
    if (length(plots) == 0) {
      plot.new()
      text(0.5, 0.5, "No variables had missing values to plot.", col = "red", cex = 1.2)
    } else {
      grid.arrange(grobs = plots, ncol = 3)
    }
    
  })
    
    output$miss_codeOutput <- renderText({
      
      req(input$miss_outcome, input$miss_percent, input$miss_type)
      
      code <- c()
      code <- c(code, "df <- read.csv(\"path_to_your_file.csv\")",
                "")
      
      code <- c(code,
                "# Convert all binary variables to factors",
                "is_binary <- function(x) length(unique(x)) == 2",
                "binary_vars <- sapply(df, is_binary)",
                "df[, binary_vars] <- lapply(df[, binary_vars, drop = FALSE], as.factor)",
                ""
      )
      
      code <- c(code,
                "gg_miss_var(df)  # number of missing values per variable",
                "gg_miss_upset(df)  # relationships between missingness",
                paste0("gg_miss_fct(x = df, fct = ", input$miss_outcome, ")  # plot missing by group"),
                ""
      )
      
      if (as.numeric(input$miss_percent) != 0) {
        code <- c(code,
                  paste0("# Exclude variables with >", input$miss_percent, "% missingness",
                         "\npercent_missing <- colSums(is.na(df)) / nrow(df) * 100",
                         "\ndf <- df[, percent_missing <= ", input$miss_percent, "]"),
                  ""
        )
      }
      
      if (input$miss_type == "Listwise Deletion") {
        code <- c(code, "# Listwise deletion",
                  "df_imputed <- df[complete.cases(df), ]",
                  "")
      } else if (input$miss_type == "Single Stat") {
        code <- c(code,
                  "# Define single-stat imputation function",
                  "impute_single_stat <- function(df) {",
                  "  df_imputed <- df  # preserve original",
                  "  for (col in names(df)) {",
                  "    if (any(is.na(df[[col]]))) {",
                  "      if (is.numeric(df[[col]]) && !is.ordered(df[[col]])) {",
                  "        df_imputed[[col]][is.na(df[[col]])] <- mean(df[[col]], na.rm = TRUE)",
                  "      } else if (is.factor(df[[col]]) && nlevels(df[[col]]) == 2) {",
                  "        mode_val <- names(which.max(table(df[[col]])))",
                  "        df_imputed[[col]][is.na(df[[col]])] <- mode_val",
                  "        df_imputed[[col]] <- droplevels(df_imputed[[col]])",
                  "      } else if (is.ordered(df[[col]])) {",
                  "        ord_vals <- as.integer(df[[col]])",
                  "        med_val <- median(ord_vals, na.rm = TRUE)",
                  "        levels_ord <- levels(df[[col]])",
                  "        df_imputed[[col]][is.na(df[[col]])] <- levels_ord[round(med_val)]",
                  "      }",
                  "    }",
                  "  }",
                  "",
                  "  return(df_imputed)",
                  "}",
                  "",
                  "# Run single stat imputation",
                  "df_imputed <- impute_single_stat(df)",
                  ""
        )
      } else {
        code <- c(code,
                  "# Random forest imputation",
                  "df_imputed <- missRanger(df, num.trees = 100, verbose = 0, seed = 42)",
                  ""
        )
      }
      
      code <- c(code,
                "# Visualize observed vs. imputed values for one variable",
                "var <- \"var_to_plot\"  # replace with variable of interest",
                "",
                "df_plot <- df %>%",
                "  mutate(",
                "    imputed = ifelse(is.na(.data[[var]]), \"Imputed\", \"Observed\"),",
                "    value = ifelse(is.na(.data[[var]]), df_imputed[[var]], .data[[var]])",
                "  )",
                "",
                "ggplot(df_plot, aes(x = imputed, y = value, color = imputed)) +",
                "  geom_jitter(width = 0.2, alpha = 0.7, size = 1.5) +",
                "  labs(title = var, x = NULL, y = NULL) +",
                "  scale_color_manual(values = c(\"Imputed\" = \"#F8766D\", \"Observed\" = \"#00BFC4\")) +",
                "  theme_minimal()",
                ""
      )
      
      code <- c(code,
                "# Save imputed file",
                "write.csv(df_imputed, file = \"path_to_file.csv\")"
      )
      
      paste(code, collapse = "\n")
    }) # end code output
  
 
  output$miss_helpOutput <- renderUI({
    includeMarkdown(normalizePath("Miss_Data_Help.Rmd"))
  })
  
}

miss_app <- list(ui = miss_ui, server = miss_server)