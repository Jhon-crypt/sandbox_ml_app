# Shiny Clustering App

# UI
clust_ui <- tagList(
  titlePanel("Clustering Analysis"),
 
  sidebarLayout(
    sidebarPanel(
      helpText(tags$em("File should contain only the variables selected for clustering and have no missing data.")),
      fileInput("clust_datafile", "Upload CSV File", accept = ".csv"),
      
      selectInput("method", "Clustering Method:",
                  choices = c("K-means (Euclidean)", 
                              "K-medoids (Manhattan)", 
                              "K-medoids (Gower)")),
      
      radioButtons("k_mode", "Choose number of clusters:",
                   choices = c("Auto", "Manual"),
                   selected = "Auto"),
      
      conditionalPanel(
        condition = "input.k_mode == 'Manual'",
        numericInput("clusters", "Number of Clusters (k):", value = 3, min = 2)
      ),
      
      checkboxInput("scale_data", "Standardize the data?", FALSE),
      
      checkboxInput("save_model", "Save data?", FALSE),
      helpText(tags$em("Saves the cluster model and the original dataset with cluster assignments.")),
      
      conditionalPanel(
        condition = "input.save_model == true",
        shinyDirButton("clust_save_dir", "Choose Save Directory", "Select folder to save output"),
        textInput("model_name", "Model file name (.RData):", value = "clustering_model.RData"),
        textInput("csv_name", "Clustered data (.csv):", value = "clustered_data.csv")
      ),
      
      actionButton("run", "Run Clustering"),
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Plots",
                 tags$p("Tip: right click on a plot to save it.", 
                        style = "color: gray; font-style: italic; margin-top: 10px;"),
                 verbatimTextOutput("clust_codeOutput"),
                 plotOutput("silPlot"),
                 verbatimTextOutput("silMean"),
                 plotOutput("pcaPlot", height = "600px"),
                 
        ),
        tabPanel("Code",
                 h4("Clustering Code"),
                 tags$p("Tip: you must run clustering before code will be generated.", 
                        style = "color: gray; font-style: italic; margin-top: 10px;"),
                 verbatimTextOutput("clust_codeOutput")
        ),
        
        tabPanel("Data",
                 h4("Uploaded Dataset"),
                 DT::dataTableOutput("clust_dataView")
        ),
        
        tabPanel("Help",
                 h4(""),
                 uiOutput("clust_helpOutput")
        )
      )
    )
  )
)


# Server
clust_server <- function(input, output, session) {
  volumes <- c(Home = fs::path_home(), getVolumes()())
  shinyDirChoose(input, "clust_save_dir", roots = volumes, session = session)
  
  clust_save_path <- reactive({
    if (is.null(input$clust_save_dir)) return(NULL)
    parseDirPath(volumes, input$clust_save_dir)
  })
  
  clust_data <- reactive({
    req(input$clust_datafile)
    df <- read.csv(input$clust_datafile$datapath)
    df[sapply(df, is.numeric)]
  })
  
  output$clust_dataView <- DT::renderDataTable({
    req(input$clust_datafile)
    df <- read.csv(input$clust_datafile$datapath)
    df
  })
  
  clustering_result <- eventReactive(input$run, {
    set.seed(42)
    
    withProgress(message = "Clustering the data...", value = 0, {
    df_raw <- clust_data()
    
    # Detect variable types
    is_binary <- function(x) is.numeric(x) && all(x %in% c(0, 1)) && length(unique(x)) == 2
    binary_vars <- sapply(df_raw, is_binary)
    continuous_vars <- !binary_vars
    
    # Conditional scaling
    df <- if (input$scale_data) {
      df_scaled <- df_raw
      df_scaled[, continuous_vars] <- scale(df_raw[, continuous_vars])
      as.data.frame(df_scaled)
    } else {
      df_raw
    }
    
    incProgress(0.2)
    
    method <- input$method
    k_mode <- input$k_mode
    
    # Compute distance matrix only for PAM
    if (method == "K-means (Euclidean)") {
      dist_mat <- NULL
    } else if (method == "K-medoids (Manhattan)") {
      dist_mat <- dist(df, method = "manhattan")
    } else {
      dist_mat <- daisy(df, metric = "gower")
    }
    
    incProgress(0.3)
    
    # Determine optimal k if selected
    if (k_mode == "Auto (optimize using silhouette width)") {
      sil_width <- c(NA)
      for (i in 2:10) {
        fit <- pam(dist_mat, k = i, diss = TRUE)
        sil_width[i] <- fit$silinfo$avg.width
      }
      k <- which.max(sil_width)
    } else {
      k <- input$clusters
    }
    
    incProgress(0.5)
    
    # Run clustering
    if (method == "K-means (Euclidean)") {
      clust_model <- kmeans(df, centers = k, nstart = 25)
      clusters <- clust_model$cluster
    } else {
      clust_model <- pam(dist_mat, k = k, diss = TRUE, medoids = "random", nstart = 25)
      clusters <- clust_model$clustering
    }
    
    incProgress(1, detail = "Done!")
    })
    
    # Silhouette
    if (!is.null(dist_mat)) {
      sil <- silhouette(clusters, dist_mat)
      mean_sil <- mean(sil[, 3])
    } else {
      sil <- silhouette(clusters, dist(df))
      mean_sil <-mean(sil[,3])
    }
    
    # Visualization
    clust_obj <- list(cluster = clusters)
    class(clust_obj) <- "kmeans"  # works with fviz_cluster
    pca_plot <- fviz_cluster(clust_obj, data = df, geom = "point", ellipse.type = "norm",
                             ggtheme = theme_minimal(), main = "PCA Plot")
    
    # Save if requested
    if (input$save_model && !is.null(clust_save_path())) {
      dir_path <- clust_save_path()
      save(clust_model, file = file.path(dir_path, input$model_name))
      df_out <- df
      df_out$cluster <- clusters
      write.csv(df_out, file.path(dir_path, input$csv_name), row.names = FALSE)
    }
    
    list(sil = sil, mean_sil = mean_sil, pca_plot = pca_plot)
    
  })

  
  output$silPlot <- renderPlot({
    req(clustering_result())
      fviz_silhouette(clustering_result()$sil) +
        ggtitle("Silhouette Plot")
  })
  
  
  output$silMean <- renderPrint({
    req(clustering_result())
    cat("Mean Silhouette Width:", round(clustering_result()$mean_sil, 3))
  })
  
  output$pcaPlot <- renderPlot({
    req(clustering_result())
    print(clustering_result()$pca_plot)
  })
  
  
  output$clust_codeOutput <- renderText({
    req(input$run > 0)
    method <- input$method
    k_mode <- input$k_mode
    scale_on <- input$scale_data
    
    code_lines <- c(
      "set.seed(42)  # ensures reproducibility",
      "",
      "df_raw <- read.csv(...)  # load data",
      "",
      "# detect variable type",
      "is_binary <- function(x) is.numeric(x) && all(x %in% c(0, 1)) && length(unique(x)) == 2",
      "binary_vars <- sapply(df_raw, is_binary)",
      "continuous_vars <- !binary_vars",
      ""
    )
    
    if (scale_on) {
      code_lines <- c(code_lines,
                      "",
                      "# scale continuous variables only",
                      "df_scaled <- df_raw",
                      "df_scaled[, continuous_vars] <- scale(df_raw[, continuous_vars])",
                      "df <- as.data.frame(df_scaled)",
                      ""
      )
    } else {
      code_lines <- c(code_lines, "", "df <- df_raw",
                      "")
    }
    
    if (k_mode == "Auto (optimize using silhouette width)") {
      code_lines <- c(code_lines,
                      "",
                      "# determine optimal number of clusters",
                      "sil_width <- c(NA)",
                      "for (i in 2:10) {",
                      "  fit <- pam(dist_mat, k = i, diss = TRUE)",
                      "  sil_width[i] <- fit$silinfo$avg.width",
                      "}",
                      "k <- which.max(sil_width)",
      )
    }
    
    if (method == "K-means (Euclidean)") {
      code_lines <- c(code_lines,
                      "",
                      "# k-means clustering",
                      "clust_model <- kmeans(df, centers = k, nstart = 25)"
      )
    } else if (method == "K-medoids (Manhattan)") {
      code_lines <- c(code_lines,
                      "",
                      "# manhattan distance for PAM",
                      "dist_mat <- dist(df, method = 'manhattan')",
                      "clust_model <- pam(dist_mat, k = k, diss = TRUE, medoids = 'random', nstart = 25)"
      )
    } else if (method == "K-medoids (Gower)") {
      code_lines <- c(code_lines,
                      "",
                      "# gower distance for PAM",
                      "dist_mat <- daisy(df, metric = 'gower')",
                      "clust_model <- pam(dist_mat, k = k, diss = TRUE, medoids = 'random', nstart = 25)"
      )
    }
    
    paste(code_lines, collapse = "\n")
  })
  
  output$clust_helpOutput <- renderUI({
    includeMarkdown("Clustering_Help.Rmd")
  })
  
}

clust_app <- list(ui = clust_ui, server = clust_server)
