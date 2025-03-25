library(shiny)
library(cowplot)
library(ggplot2)
library(openxlsx)
library(DT)
library(purrr)
library(igraph)
library(plotly)
library(RColorBrewer)
library(dplyr)
library(tidyr)
library(shinycssloaders)

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
source("R/gene_network.R")

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
    div(
      class = "title-panel", "CancerHubs Data Explorer")
  ),
  
  sidebarLayout(
    createSidebar(),
    createMainPanel()
  ),  div(
    class = "footer",
    style = "position: fixed; bottom: 0; width: 100%; background: #f5f9fc; text-align: center; padding: 8px;",
    HTML(
      "N.B.: This app relies on mutational data that do not account for Copy Number Variations. Consequently, neither the network score-based rankings nor the pan-cancer score considers them."
      
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
    
    df$mut_int_percentage <- round((df$mut_int / df$tot_int * 100),2)
    
    df = df[, c("gene_list","mutation","precog_metaZ","tot_int", "mut_int", "mut_int_percentage", "network_score")]
    
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
  
  
  
  
  #RANKING
  
  # Reactive function to calculate rankings for the selected gene
  get_gene_ranking_reactive <- reactive({
    req(input$gene, input$dataframe_subset)
    
    # Get the ranking data
    ranking_data <- get_gene_ranking(input$gene, input$dataframe_subset, data)
    
    return(ranking_data)
  })
  
  
  # Reactive function to calculate rankings for the selected gene
  pan_cancer_ranking_reactive <- reactive({
    req(input$dataframe_subset)
    
    # Get the ranking data
    pan_cancer_results<- pan_cancer_ranking(data,input$dataframe_subset)
    
    return(pan_cancer_results)
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
      
      # Ensure required inputs are available
      req(input$gene)
      req(input$dataframe_subset)
      
      
      # Retrieve data
      gene_rankings <- get_gene_ranking_reactive()
      
      
      # Retrieve pan_cancer_results
      
      pan_cancer_results <- tryCatch({
        pan_cancer_ranking_reactive()
      }, error = function(e) {
        message("ERROR: pan_cancer_ranking_reactive() failed: ", e$message)
        return(NULL)
      })
      
      if (is.null(pan_cancer_results)) {
        message("ERROR: pan_cancer_results is NULL. Stopping execution.")
        return(NULL)
      }
      
      
      # Generate the plots
      ranking_plot <- create_ranking_plot(gene_rankings, input$gene, input$dataframe_subset)
      pan_cancer_plot <- create_pan_cancer_position_plot(pan_cancer_results, input$gene)
      
      ranking_plot <- ranking_plot + theme(plot.margin = margin(t = 130, r = 0, b = 100, l = 5, unit = "pt")) + guides(color = guide_legend(nrow = 3))
      pan_cancer_plot <- pan_cancer_plot + theme(plot.margin = margin(t = 0, r = 50, b = 75, l = 0, unit = "pt"))
      
      
      
      # Combine the plots using cowplot
      combined_plot <- plot_grid(ranking_plot, pan_cancer_plot, ncol = 1, align = "v", rel_heights = c(4, 1), rel_widths = c(1, 7))
      
      ggsave(file, plot = combined_plot, device = "pdf", width = 8, height = 12)
      
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
  
  output$pan_cancer_gene_position <- renderPlot({
    req(input$gene, input$dataframe_subset)  # Ensure inputs are provided
    
    # Calculate pan-cancer ranking
    pan_cancer_results <- pan_cancer_ranking(data = data, df = input$dataframe_subset)
    
    # Create the plot using the new function
    create_pan_cancer_position_plot(pan_cancer_results, input$gene)
  })
  
  output$download_pan_cancer <- downloadHandler(
    filename = function() {
      paste("pan_cancer_ranking_", input$dataframe_subset, ".xlsx", sep = "")
    },
    content = function(file) {
      # Generate the pan-cancer ranking data
      pan_cancer_results <- pan_cancer_ranking(data, input$dataframe_subset)
      
      # Ensure the data exists
      req(nrow(pan_cancer_results) > 0)
      
      # Write to an Excel file
      openxlsx::write.xlsx(pan_cancer_results,file)
    }
  ) 
  
  
  
  
  #NETWORK
  
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
      if (gene %in% names(interactors$gene_interactors)) {
        interactors_list <- interactors$gene_interactors[[gene]]
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
  
  
  # Render the network legend
  output$network_legend_plot <- renderPlot({
    plot.new()
  })
  
  output$network_plot <- renderPlotly({
    req(input$network_tumor, input$network_dataset_type, input$network_color_by)
    
    # Time the ggplotly conversion
    start_time <- Sys.time()
    
    # Generate the Plotly plot
    plot <- plot_tumor_network(data, interactors, 
                               tumor = input$network_tumor, 
                               dataset_type = input$network_dataset_type, 
                               top_n = input$network_top_n, 
                               mutated_interactors = input$network_mutated_interactors, 
                               color_by = input$network_color_by)
    
    # Add custom configuration for higher resolution
    plot %>%
      config(
        toImageButtonOptions = list(
          format = "png",  # Format can be png, jpeg, etc.
          width = 2880,    # Increase width for higher resolution
          height = 1620,   # Increase height for higher resolution
          scale = 3        # Scale factor for resolution
        )
      )
    
    end_time <- Sys.time()
    
    message(paste("network generation took", round(end_time - start_time, 2), "seconds"))
    
    plot
    
  })
  
  
  
  
  
  #COMMON GENES
  
  # Reactive value to store the selected dataframe
  selected_df <- reactiveVal("All_Genes")
  
  # Event to extract genes and prepare data for download
  extracted_data_reactive <- reactive({
    req(input$num_lines, input$num_cancers,input$selected_dataframe)  # Ensure parameters are provided
    
    
    n <- input$num_lines
    num_cancers <- input$num_cancers
    top_lines <- extract_top_n_lines(data, n)  # Assuming this function is defined elsewhere
    
    # Use the modified function to get common genes
    common_genes <- get_common_genes_across_cancers(top_lines, num_cancers, selection = input$selected_dataframe)

    
    
     # Return the common genes data
    return(common_genes)
  })
  
  
  
  
  # Observe the selected dataframe input and update the reactive value
  observeEvent(input$selected_dataframe, {
    selected_df(input$selected_dataframe)
  })
  

  
  # Reactive expression to run the analysis
  analysis_result <- reactive( {
    
    start_time = Sys.time()
    
    req(input$num_lines,input$num_cancers)
    # Assuming 'data' is available in your app's environment
    extracted_data <- extract_top_n_genes(data, input$num_lines)
    gene_presence_df <- create_presence_matrix_per_category(extracted_data)
    heatmaps <- create_category_heatmaps(gene_presence_df, top_n = input$num_lines,num_cancers = input$num_cancers)
    
    
    end_time <- Sys.time()  # End timer
    
    # Compute elapsed time
    elapsed_time <- end_time - start_time
    message(paste("Analysis completed in", round(elapsed_time, 2), "seconds"))
    
    return(heatmaps)
  })
  
  
  
  output$heatmap_output <- renderPlotly({
    req(analysis_result())
    
    heatmaps <- analysis_result()
    selected <- selected_df()
    req(selected %in% names(heatmaps))
    
    heatmap <- heatmaps[[selected]]
    req(heatmap)
    
    plotly_heatmap <- heatmap
    
    plotly_heatmap %>%
      config(
        toImageButtonOptions = list(
          format = "svg",  # Format can be png, jpeg, etc.
          width = NULL,      # Even higher width for higher resolution
          height = NULL      # Scale factor for resolution
        )
      )
    
    
    plotly_heatmap
  })
  
  
  # Provide download for the extracted data as XLSX
  output$download_extracted_data <- downloadHandler(
    filename = function() {
      paste("Extracted_Genes_", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      selected_df <- extracted_data_reactive()
      req(selected_df)
      
      # Write each subset as a sheet in the Excel file
      write.xlsx(selected_df, file)
    }
  )
  
  output$network_legend_plot <- renderPlot({
    plot.new()
  })
  
  #GENE NETWORK
  
  output$gene_network <- renderPlot({
    req(input$network_tumor, input$gene,input$data_type_precog, input$gene)
    
    # Time the ggplotly conversion
    start_time <- Sys.time()
    
    # Generate the Plotly plot
    plot <- create_network(data = gene_interactors, 
                               original = data,
                               cancer_type = input$network_tumor,
                               gene = input$gene, 
                               int_type =input$data_type_precog,
                               include_mutated = input$g_network_mutated_interactors,
                               crosses = input$cross)
    
    
    
    end_time <- Sys.time()
    
    total = end_time - start_time
    print(total)
  })
  
  output$downloadGeneNetwork <- downloadHandler(
    filename = function() {
      paste("gene_network_plot_", Sys.Date(), ".pdf", sep = "")
    },
    content = function(file) {
      # Generate the igraph object using create_network
      g <- create_network(data = gene_interactors, original = data,
                          cancer_type = input$network_tumor, gene = input$gene, 
                          int_type = input$data_type_precog,include_mutated = input$g_network_mutated_interactors,
                          crosses = input$cross)
      
      # Check if the plot is an igraph object
        pdf(file, width = 10, height = 8)  # Open a PDF graphics device
        
        # Apply your custom plotting parameters
        plot(g,
             vertex.size = 10, vertex.label.cex = 1,
             vertex.color = V(g)$color,
             vertex.frame.color = V(g)$color,
             vertex.label.color = "black",vertex.label.font = 2,
             main = paste("Top50 Interactors of", input$gene))
        legend(
          x = 0.2, y = -1,
          legend = c(input$gene,"Interactors with Network Score", "Interactors with Network Score equal to 0"),
          col = c( "pink","#83C9C8", "#C9E8E7"),
          pch = 21,
          pt.bg = c("pink","#83C9C8", "#C9E8E7"),
          pt.cex = 2,
          bty = "n",
          xpd = TRUE  # Allow the legend to be drawn outside the plot region
        )
        
        dev.off()  # Close the graphics device
      
    }
  )
  

  
  selected_file_link <- reactiveVal(NULL)
  
  # Observe event when user selects parameters
  observe( {
    link <- get_file_link(input$network_tumor, input$data_type_precog, input$g_network_mutated_interactors)
    selected_file_link(link)
  })
  
  # Download handler
  output$downloadData <- downloadHandler(
    filename = function() {
      basename(selected_file_link())  # Extracts file name from URL
    },
    content = function(file) {
      if (is.null(selected_file_link())) {
        stop("No file selected.")
      }
      download.file(selected_file_link(), file, mode = "wb")  # Download the file
    }
  )

  
}

shinyApp(ui = ui, server = server)
