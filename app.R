library(shiny)
library(ggplot2)
library(openxlsx)
library(DT)
library(plotly)

# Load the RDS files
data <- readRDS(url("https://github.com/ingmbioinfo/cancerhubs/raw/refs/heads/main/result/all_results.rds"))
interactors <- readRDS(url("https://github.com/ingmbioinfo/cancerhubs/raw/refs/heads/main/data/biogrid_interactors"))

# Source the styles and functions from the R subdirectory
source("R/styles.R")  # Define cancerhubs_style
source("R/sidebar_functions.R")
source("R/main_panel_functions.R")
source("R/gene_ranking_functions.R")
source("R/plot_functions.R")
source("R/network_plot_functions.R")  # Load the new network plot function

# Define UI (Make sure cancerhubs_style is available here)
ui <- fluidPage(
  tags$head(
    tags$style(HTML(sprintf("
      body {
        background-color: %s;
        font-family: 'Arial', sans-serif;
      }
      .title-panel {
        text-align: center;
        color: %s;
        font-weight: bold;
      }
      .sidebar {
        background-color: %s;
        border-radius: 10px;
        padding: 15px;
        box-shadow: 2px 2px 5px rgba(0,0,0,0.1);
      }
      .main-panel {
        border-radius: 10px;
        padding: 20px;
        background-color: white;
        box-shadow: 2px 2px 5px rgba(0,0,0,0.1);
      }
      table {
        width: 100%%;
        margin-top: 10px;
      }
      th {
        background-color: %s;
        color: white;
      }
    ",
                            cancerhubs_style$background,
                            cancerhubs_style$primary_text,
                            cancerhubs_style$sidebar_bg,
                            cancerhubs_style$button_bg
    )))
  ),
  
  titlePanel(
    div(class = "title-panel", "CancerHubs Data Explorer")
  ),
  
  sidebarLayout(
    sidebarPanel(
      div(class = "sidebar",
          conditionalPanel(
            condition = "input.tabSelected === 'View Dataframe'",
            selectInput("cancer_type_df", "Select Cancer Type:", choices = names(data)),
            selectInput("dataframe", "Select Dataframe:",
                        choices = c("All Genes" = "All_Genes", 
                                    "PRECOG" = "PRECOG", 
                                    "Non PRECOG" = "Non_PRECOG",
                                    "Only PRECOG" = "Only_PRECOG")),
            downloadButton("download_dataframe", "Download Dataframe (XLSX)")
          ),
          conditionalPanel(
            condition = "input.tabSelected === 'Gene Ranking'",
            textInput("gene", "Enter Gene Name:", value = "TP53"),
            selectInput("dataframe_subset", "Select Dataframe Subset:",
                        choices = c("All Genes" = "All_Genes", 
                                    "PRECOG" = "PRECOG", 
                                    "Non PRECOG" = "Non_PRECOG",
                                    "Only PRECOG" = "Only_PRECOG")),
            DTOutput("ranking_table"),
            downloadButton("download_plot", "Download Plot (PDF)"),
            downloadButton("download_ranking_table", "Download Ranking Table (XLSX)")
          ),
          conditionalPanel(
            condition = "input.tabSelected === 'Network Plot'",
            h4("Nodes Table"),
            DTOutput("nodes_table"),
            downloadButton("download_network_nodes", "Download Nodes Table (XLSX)"),
            br(), br(),
            h4("Edges Table"),
            DTOutput("edges_table"),
            downloadButton("download_network_edges", "Download Edges Table (XLSX)")
          )
      )
    ),
    mainPanel(
      div(class = "main-panel",
          tabsetPanel(
            id = "tabSelected",
            tabPanel("View Dataframe", value = "View Dataframe", DTOutput("data_view")),
            tabPanel("Gene Ranking", value = "Gene Ranking", plotOutput("ranking_plot", height = "600px")),
            tabPanel("Network Plot", value = "Network Plot",
                     fluidRow(
                       column(3, selectInput("network_tumor", "Select Tumor:", choices = names(data))),
                       column(3, selectInput("network_dataset_type", "Select Dataset Type:", choices = c("All_Genes", "PRECOG", "Non_PRECOG", "Only_PRECOG"))),
                       column(3, numericInput("network_top_n", "Number of Top Genes:", value = 10, min = 1)),
                       column(3, checkboxInput("network_mutated_interactors", "Include Only Mutated Interactors", value = TRUE))
                     ),
                     plotlyOutput("network_plot", height = "600px"),
                     br(),
                     h4("Legend"),
                     plotOutput("network_legend_plot")
            )
          )
      )
    )
  )
)

# Server logic
server <- function(input, output, session) {
  # Reactive to fetch the selected dataframe
  selected_data_df <- reactive({
    req(input$cancer_type_df, input$dataframe)
    
    df <- data[[input$cancer_type_df]][[input$dataframe]]
    
    # Check if data is available
    if (is.null(df)) {
      return(data.frame())  # Return an empty dataframe if not available
    }
    
    return(df)
  })
  
  # Display the selected dataframe for "View Dataframe" with interactive features
  output$data_view <- renderDT({
    df <- selected_data_df()
    req(nrow(df) > 0)  # Ensure there is at least one row before rendering
    
    datatable(df, options = list(pageLength = 10, scrollX = TRUE))
  })
  
  # Provide download for the dataframe as XLSX
  output$download_dataframe <- downloadHandler(
    filename = function() {
      paste(input$cancer_type_df, '_', input$dataframe, ".xlsx", sep = "")
    },
    content = function(file) {
      write.xlsx(selected_data_df(), file)
    }
  )
  
  # Reactive function to calculate rankings for the selected gene
  get_gene_ranking_reactive <- reactive({
    req(input$gene, input$dataframe_subset)
    
    # Get the ranking data
    ranking_data <- get_gene_ranking(input$gene, input$dataframe_subset, data)
    
    return(ranking_data)
  })
  
  # Render the plot for gene rankings
  output$ranking_plot <- renderPlot({
    rankings <- get_gene_ranking_reactive()
    
    if (nrow(rankings) == 0) {
      plot(1, type = "n", xlab = "", ylab = "", main = "Gene not found in any tumor type")
    } else {
      create_ranking_plot(rankings, input$gene, input$dataframe_subset)
    }
  })
  
  # Render the table for gene rankings
  output$ranking_table <- renderDT({
    rankings <- get_gene_ranking_reactive()
    req(nrow(rankings) > 0)  # Ensure there is at least one row before rendering
    
    datatable(rankings, options = list(pageLength = 5, scrollX = TRUE), rownames = FALSE)
  })
  
  # Provide download for the plot as PDF
  output$download_plot <- downloadHandler(
    filename = function() {
      paste(input$gene, "_ranking_plot.pdf", sep = "")
    },
    content = function(file) {
      pdf(file, width = 10, height = 7)
      rankings <- get_gene_ranking_reactive()
      if (nrow(rankings) > 0) {
        print(create_ranking_plot(rankings, input$gene, input$dataframe_subset))
      }
      dev.off()
    }
  )
  
  # Provide download for the ranking table as XLSX
  output$download_ranking_table <- downloadHandler(
    filename = function() {
      paste(input$gene, "_ranking_table.xlsx", sep = "")
    },
    content = function(file) {
      write.xlsx(get_gene_ranking_reactive(), file)
    }
  )
  
  # Reactive to fetch nodes and edges data for the network plot
  network_data <- reactive({
    req(input$network_tumor, input$network_dataset_type)
    
    tumor_data <- data[[input$network_tumor]][[input$network_dataset_type]]
    top_genes <- head(tumor_data[order(-tumor_data$network_score), ], input$network_top_n)
    
    # Extract nodes and edges for the network
    nodes <- data.frame(
      name = top_genes$gene_list,
      score = top_genes$network_score,
      precog_metaZ = top_genes$precog_metaZ,
      mutation = top_genes$mutation,
      stringsAsFactors = FALSE
    )
    edges <- list()
    for (gene in nodes$name) {
      if (gene %in% names(interactors$as.matrix.interactors.)) {
        interactors_list <- interactors$as.matrix.interactors.[[gene]]
        interactors_list <- interactors_list[interactors_list %in% nodes$name]
        for (interactor in interactors_list) {
          if (gene != interactor) {
            edges <- append(edges, list(c(gene, interactor)))
          }
        }
      }
    }
    edges_df <- do.call(rbind, edges)
    edges_df <- as.data.frame(edges_df, stringsAsFactors = FALSE)
    colnames(edges_df) <- c("from", "to")
    
    list(nodes = nodes, edges = edges_df)
  })
  
  # Display nodes table
  output$nodes_table <- renderDT({
    nodes <- network_data()$nodes
    req(nrow(nodes) > 0)  # Ensure there is at least one row before rendering
    
    datatable(nodes, options = list(pageLength = 10, scrollX = TRUE))
  })
  
  # Display edges table
  output$edges_table <- renderDT({
    edges <- network_data()$edges
    req(nrow(edges) > 0)  # Ensure there is at least one row before rendering
    
    datatable(edges, options = list(pageLength = 10, scrollX = TRUE))
  })
  
  # Provide download for the edges table as XLSX
  output$download_network_edges <- downloadHandler(
    filename = function() {
      paste(input$network_tumor, '_', input$network_dataset_type, "_edges.xlsx", sep = "")
    },
    content = function(file) {
      write.xlsx(network_data()$edges, file)
    }
  )
  
  # Provide download for the nodes table as XLSX
  output$download_network_nodes <- downloadHandler(
    filename = function() {
      paste(input$network_tumor, '_', input$network_dataset_type, "_nodes.xlsx", sep = "")
    },
    content = function(file) {
      write.xlsx(network_data()$nodes, file)
    }
  )
  
  # Render the network plot
  output$network_plot <- renderPlotly({
    req(input$network_tumor)
    req(input$network_dataset_type)
    
    # Call the plot_tumor_network function to generate the plotly object
    plot_tumor_network(data, interactors, tumor = input$network_tumor, dataset_type = input$network_dataset_type, top_n = input$network_top_n, mutated_interactors = input$network_mutated_interactors)
  })
  
  # Render the network legend
  output$network_legend_plot <- renderPlot({
    plot.new()
  })
}

shinyApp(ui = ui, server = server)
