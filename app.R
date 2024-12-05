library(shiny)
library(ggplot2)
library(openxlsx)
library(DT)
library(igraph)
library(plotly)
library(RColorBrewer)
library(dplyr)
library(tidyr)

# Source the styles and functions from the R subdirectory
source("R/data.R")
source("R/styles.R")  # Define cancerhubs_style
source("R/sidebar_functions.R")
source("R/main_panel_functions.R")
source("R/gene_ranking_functions.R")
source("R/plot_functions.R")
source("R/network_plot_functions.R")  # Load the new network plot function
source("R/common_genes_function.R")
source("R/heatmaps_functions.R")

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
    createSidebar(),
    createMainPanel()
  ),
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
    req(input$network_color_by)
    
    # Call the plot_tumor_network function to generate the plotly object
    plot_tumor_network(data, interactors, tumor = input$network_tumor, dataset_type = input$network_dataset_type, 
                       top_n = input$network_top_n, mutated_interactors = input$network_mutated_interactors, color_by = input$network_color_by)
  })
  
  # Render the network legend
  output$network_legend_plot <- renderPlot({
    plot.new()
  })
  
  
  
  # Event to extract genes and prepare data for download
  extracted_data_reactive <- reactive({
    req(input$num_lines, input$num_cancers)  # Ensure parameters are provided
    n <- input$num_lines
    num_cancers <- input$num_cancers
    top_lines <- extract_top_n_lines(data, n)  # Assuming this function is defined elsewhere
    
    # Use the modified function to get common genes
    common_genes <- get_common_genes_across_cancers(top_lines, num_cancers)
    
    # Return the common genes data
    return(common_genes)
  })
  
  
  # Reactive value to store the selected dataframe
  selected_df <- reactiveVal("All_Genes")
  
  # Observe the selected dataframe input and update the reactive value
  observeEvent(input$selected_dataframe, {
    selected_df(input$selected_dataframe)
  })
  
  # Reactive expression to run the analysis
  analysis_result <- reactive( {
    req(input$num_lines)
    # Assuming 'data' is available in your app's environment
    extracted_data <- extract_top_n_genes(data, input$num_lines)
    gene_presence_df <- create_presence_matrix_per_category(extracted_data)
    heatmaps <- create_category_heatmaps(gene_presence_df, top_n = input$num_lines)
    return(heatmaps)
  })
  
  output$heatmap_output <- renderPlotly({
    req(analysis_result())
    heatmaps <- analysis_result()
    
    # Validate selected dataframe
    selected <- selected_df()
    req(selected %in% names(heatmaps))
    
    # Extract and validate heatmap
    heatmap <- heatmaps[[selected]]
    req(heatmap)
    
    # Convert ggplot to plotly
    ggplotly(heatmap)
  })
  
  output$download_high_res <- downloadHandler(
    filename = function() {
      paste("heatmap_high_res", Sys.Date(), ".png", sep = "")
    },
    content = function(file) {
      heatmaps <- analysis_result()
      selected <- selected_df()
      heatmap <- heatmaps[[selected]]
      
      ggsave(file, plot = heatmap, device = "png", width = 12, height = 8, dpi = 300)
    }
  )
  
  
  
  # Provide download for the extracted data as XLSX
  output$download_extracted_data <- downloadHandler(
    filename = function() {
      paste("Extracted_Genes_", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      category_genes <- extracted_data_reactive()
      req(category_genes)
      
      # Write each subset as a sheet in the Excel file
      write.xlsx(category_genes, file)
    }
  )
  
  
}

shinyApp(ui = ui, server = server)
