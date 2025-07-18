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
library(shinyjs)

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
source("R/gene_network_download.R")

# Define UI (Make sure cancerhubs_style is available here)
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$title("CancerHubs Data Explorer"),
    tags$meta(name = "keywords", 
              content = "CancerHubs, cancerhubs, cancer gene networks, protein interactions, network score, mutation data, precog, biogrid, cancer bioinformatics,shiny app"),
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
      .shiny-output-error-validation {
        color: #AD2727; text-align: center;
        font-size: 18px;margin-top: 300px;
      }

    ",
                            cancerhubs_style$background,
                            cancerhubs_style$primary_text,
                            cancerhubs_style$sidebar_bg,
                            cancerhubs_style$button_bg
    ))),
    tags$link(rel = "icon", type = "image/x-icon", href = "favicon.ico")
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
      "N.B.: This app relies on mutational data that do not account for Copy Number Variations. Consequently, neither the Network Score-based rankings nor the Pan-Cancer Score consider them."

    )
    
  )
)
# Server logic
server <- function(input, output, session) {
  
  observeEvent(input$go_df, updateTabsetPanel(session, "tabSelected", selected = "View Dataframe"))
  observeEvent(input$go_rank, updateTabsetPanel(session, "tabSelected", selected = "Gene Ranking"))
  observeEvent(input$go_common, updateTabsetPanel(session, "tabSelected", selected = "Common Genes"))
  observeEvent(input$go_3d, updateTabsetPanel(session, "tabSelected", selected = "Network Plot"))
  observeEvent(input$go_2d, updateTabsetPanel(session, "tabSelected", selected = "Gene Network"))
  
  # Reactive to fetch the selected dataframe
  selected_data_df <- reactive({
    req(input$cancer_type_df, input$dataframe)
    
    df <- data[[input$cancer_type_df]][[input$dataframe]]
    
    # Check if data is available
    if (is.null(df)) {
      return(data.frame())  # Return an empty dataframe if not available
    }
    
    df$mut_int_percentage <- round((df$mut_int / df$tot_int * 100),2)
    df$network_score = round(df$network_score,2)
    
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
  observeEvent(input$downloadBtn, {
    showModal(modalDialog(
      title = "Select file format",
      selectInput("file_format", "Choose format:", choices = c("Excel (.xlsx)" = "xlsx", "CSV (.csv)" = "csv")),
      footer = tagList(
        modalButton("Cancel"),
        downloadButton("download_dataframe", "Download")  # Appears inside modal
      )
    ))
  })
  
  output$download_dataframe <- downloadHandler(
    filename = function() {
      paste(input$cancer_type_df, '_', input$dataframe, ".", input$file_format, sep = "")
    },
    content = function(file) {
      data <- selected_data_df()
      
      if (input$file_format == "csv") {
        write.csv(data, file, row.names = FALSE)
      } else {
        write.xlsx(data, file)
      }
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
      validate(need(FALSE,paste(input$gene, "is not present in this dataset!\n Please check the spelling or select a different dataset type")))
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
      paste(input$gene, "_", input$dataframe_subset, "_ranking_plot.pdf", sep = "")
    },
    content = function(file) {
      
      # Ensure required inputs are available
      req(input$gene)
      req(input$dataframe_subset)
      
      
      # Retrieve data
      gene_rankings <- get_gene_ranking_reactive()
      
      if (nrow(gene_rankings) == 0) {
        validate(need(FALSE, showNotification(type = "error", duration = 15,  
                                              closeButton = TRUE,  # Show close button
                                              ui = tags$div(
                                                style = "font-size: 18px; padding: 20px; border-radius: 5px;",
                                                "No data available for this gene."))))
      }
      
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
      
      ranking_plot <- ranking_plot + theme(plot.margin = margin(t = 80, r = 5, b = 80, l = 10, unit = "pt")) + guides(color = guide_legend(nrow = 3))
      pan_cancer_plot <- pan_cancer_plot + theme(plot.margin = margin(t = 10, r = 0, b = 100, l = 50, unit = "pt"))
      
      
      
      # Combine the plots using cowplot
      combined_plot <- plot_grid(ranking_plot, pan_cancer_plot, ncol = 1, align = "v", rel_heights = c(4, 1), rel_widths = c(1, 7))
      
      ggsave(file, plot = combined_plot, device = "pdf", width = 8, height = 12)
      
    }
  )
  
  
  output$pan_cancer_gene_position <- renderPlot({
    req(input$gene, input$dataframe_subset)  # Ensure inputs are provided
    
    # Calculate pan-cancer ranking
    pan_cancer_results <- pan_cancer_ranking(data = data, df = input$dataframe_subset)
    
    print("pan_cancer")
    
    validate(need(input$gene %in% pan_cancer_results$gene_list,""))
    
    # Create the plot using the new function
    create_pan_cancer_position_plot(pan_cancer_results, input$gene)
    
    
  })
  
  observeEvent(input$downloadPCR, {
    showModal(modalDialog(
      title = "Select file format",
      selectInput("file_format_pan", "Choose format:", choices = c("Excel (.xlsx)" = "xlsx", "CSV (.csv)" = "csv")),
      footer = tagList(
        modalButton("Cancel"),
        downloadButton("download_pan_cancer", "Download")
      )
    ))
  })
  
  # Modal for Gene Ranking Download
  observeEvent(input$downloadRnk, {
    showModal(modalDialog(
      title = "Select file format",
      selectInput("file_format_ranking", "Choose format:", choices = c("Excel (.xlsx)" = "xlsx", "CSV (.csv)" = "csv")),
      footer = tagList(
        modalButton("Cancel"),
        downloadButton("download_ranking_table", "Download")
      )
    ))
  })
  
  # Pan-Cancer Ranking Download Handler
  output$download_pan_cancer <- downloadHandler(
    filename = function() {
      paste("pan_cancer_ranking_", input$dataframe_subset, ".", input$file_format_pan, sep = "")
    },
    content = function(file) {
      pan_cancer_results <- pan_cancer_ranking(data, input$dataframe_subset)
      
      req(nrow(pan_cancer_results) > 0)  # Ensure data exists
      
      if (input$file_format_pan == "csv") {
        write.csv(pan_cancer_results, file, row.names = FALSE)
      } else {
        openxlsx::write.xlsx(pan_cancer_results, file)
      }
    }
  ) 
  
  # Gene Ranking Table Download Handler
  output$download_ranking_table <- downloadHandler(
    filename = function() {
      paste(input$gene, "_", input$dataframe_subset, "_ranking_table.", input$file_format_ranking, sep = "")
    },
    content = function(file) {
      rankings <- get_gene_ranking_reactive()
      
      if (nrow(rankings) == 0) {
        validate(need(FALSE, showNotification(type = "error", duration = 15, closeButton = TRUE, 
                                              ui = tags$div(
                                                style = "font-size: 18px; padding: 20px; border-radius: 5px;",
                                                "No data available for this gene."))))
      } else {
        if (input$file_format_ranking == "csv") {
          write.csv(rankings, file, row.names = FALSE)
        } else {
          openxlsx::write.xlsx(rankings, file)
        }
      }
    }
    )

  
  
  
  # NETWORK
  
  
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
    
    
    if (is.null(edges_df)) {
      showNotification(type = "error", "No data available!", duration = 15)
      return(NULL) # This will stop the execution and return NULL
    }
    
    edges_df <- as.data.frame(edges_df, stringsAsFactors = FALSE)
    colnames(edges_df) <- c("from", "to")
    
    
    list(nodes = nodes, edges = edges_df)
  })
  

  
  observeEvent(input$downloadNtP, {
    showModal(modalDialog(
      title = "Select file format",
      selectInput("file_format_network", "Choose format:", choices = c("Excel (.xlsx)" = "xlsx", "CSV (.csv)" = "csv")),
      footer = tagList(
        modalButton("Cancel"),
        downloadButton("downloadNetworkData", "Download")
      )
    ))
  })
  
  # Network Data Download Handler
  output$downloadNetworkData <- downloadHandler(
    filename = function() {
      if (input$file_format_network == "csv") {
        paste(input$network_tumor, "_", input$network_dataset_type, "_NetworkData.zip", sep = "")
      } else {
        paste(input$network_tumor, "_", input$network_dataset_type, "_NetworkData.xlsx", sep = "")
      }
    },
    content = function(file) {
      edges <- network_data()$edges
      nodes <- network_data()$nodes
      
      req(!is.null(edges), !is.null(nodes))
      
      if (input$file_format_network == "csv") {
        # Create temp CSV files
        edges_file <- file.path(tempdir(), "edges.csv")
        nodes_file <- file.path(tempdir(), "nodes.csv")
        
        write.csv(edges, edges_file, row.names = FALSE)
        write.csv(nodes, nodes_file, row.names = FALSE)
        
        # Zip the two files
        zip::zipr(file, c(edges_file, nodes_file))
        
      } else {
        # Create Excel workbook with two sheets
        wb <- createWorkbook()
        addWorksheet(wb, "Edges")
        addWorksheet(wb, "Nodes")
        
        writeData(wb, "Edges", edges)
        writeData(wb, "Nodes", nodes)
        
        saveWorkbook(wb, file)
      }
    }
  )
  
  
  # Render the network legend
  output$network_legend_plot <- renderPlot({
    plot.new()
  })
  
  output$network_plot <- renderPlotly({
    req(input$network_tumor, input$network_dataset_type, input$network_color_by)
    
    top_n <- input$network_top_n
    if (top_n > 50) {
      top_n <- 50
      showNotification(type = "warning", duration = 15,  
                       closeButton = TRUE,  # Show close button
                       ui = tags$div(
                         style = "font-size: 15px; padding: 20px; border-radius: 5px;",
                         "The output was limited to the top 50 genes.", br(), 'Complete data is still available for download.'))
    } else if (top_n < 2) {
      top_n <- 2
      showNotification("Top genes too low, Top 2 genes are shown.", type = "warning", duration = 15)
    }
    
    # Time the ggplotly conversion
    start_time <- Sys.time()
    
    # Generate the Plotly plot
    plot <- plot_tumor_network(data, interactors, 
                               tumor = input$network_tumor, 
                               dataset_type = input$network_dataset_type, 
                               top_n = top_n, 
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
    
    # Validate if the table has only column names (no data rows)
    if (nrow(common_genes) == 0) {
      showNotification("Error: No data available", type = "error", duration = 5)
      return(NULL)  # Prevents further execution
    }
    
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
    
    if (input$num_lines > 50) {
      showNotification(type = "warning", duration = 15,  
                       closeButton = TRUE,  # Show close button
                       ui = tags$div(
                         style = "font-size: 15px; padding: 15px; border-radius: 5px;",
                         tags$p(
                           'The number of extracted lines is higher than 50, the visualisation may be affected!',
                           br(),
                           'Complete data is still available for download.'
                         )
                       ))}
    
   if (input$num_lines < 1) {validate(
      need(FALSE, "Please select a valid number of genes!")
    )}
    
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
    
    if (is.null(heatmaps[[selected]]) == TRUE) {
      validate(need(FALSE, paste("No genes found in", selected,
                               "with your selection! \n Please change dataset or tumour count.")))
    }
    
    heatmap <- heatmaps[[selected]]
  
    
    req(heatmap)
    
    plotly_heatmap <- heatmap
    
    plotly_heatmap <- plotly_heatmap %>%
      config(
        toImageButtonOptions = list(
          format = "svg",  # Format can be png, jpeg, etc.
          width = NULL,      # Even higher width for higher resolution
          height = NULL      # Scale factor for resolution
        )
      )
    
    
    plotly_heatmap
  })
  
  
  observeEvent(input$downloadCmG, {
    showModal(modalDialog(
      title = "Select file format",
      selectInput("file_format_extracted", "Choose format:", choices = c("Excel (.xlsx)" = "xlsx", "CSV (.csv)" = "csv")),
      footer = tagList(
        modalButton("Cancel"),
        downloadButton("download_extracted_data", "Download")
      )
    ))
  })
  
  # Extracted Data Download Handler
  output$download_extracted_data <- downloadHandler(
    filename = function() {
      paste("Common_Genes_", input$selected_dataframe, ".", input$file_format_extracted, sep = "")
    },
    content = function(file) {
      selected_df <- extracted_data_reactive()
      req(selected_df)
      
      if (input$file_format_extracted == "csv") {
        write.csv(selected_df, file, row.names = FALSE)
      } else {
        openxlsx::write.xlsx(selected_df, file)
      }
    }
  )

  
  output$network_legend_plot <- renderPlot({
    plot.new()
  })
  
  
  
  
  # GENE NETWORK
  
  output$gene_network <- renderPlot({
    req(input$g_network_tumor, input$gene_sel,input$data_type_precog)
    
    # Time the ggplotly conversion
    start_time <- Sys.time()
    
    
    # Generate the Plotly plot
    plot <- create_network(data = gene_interactors, 
                               original = data,
                               cancer_type = input$g_network_tumor,
                               gene = input$gene_sel, 
                               int_type =input$data_type_precog,
                               include_mutated = input$g_network_mutated_interactors,
                               crosses = input$cross)
    
    
    
    end_time <- Sys.time()
    
    total = end_time - start_time
    print(total)
  })
  
  output$downloadGeneNetwork <- downloadHandler(
    filename = function() {
      paste("gene_network_plot_", input$g_network_tumor ,"_", input$data_type_precog, "_",input$gene_sel, ".pdf", sep = "")
    },
    content = function(file) {
      # Generate the igraph object using create_network
      g <- tryCatch(
        {create_network(data = gene_interactors, original = data,
                       cancer_type = input$g_network_tumor, gene = input$gene_sel, 
                       int_type = input$data_type_precog,include_mutated = input$g_network_mutated_interactors,
                       crosses = input$cross)},
        error = function(e) {
          showNotification("Error: Data could not be generated.", type = "error")
          return(NULL)  # Return NULL on error
          }
      ) 
      
      
      
      # Check if the plot is an igraph object
        pdf(file, width = 10, height = 8)  # Open a PDF graphics device
        
        if (is.null(g)) {
          stop("Error: No data to plot.")
        }
        
        # Apply your custom plotting parameters
        plot(g,
             vertex.size = 10, vertex.label.cex = 1,
             vertex.color = V(g)$color,
             vertex.frame.color = V(g)$color,
             vertex.label.color = "black",vertex.label.font = 2,
             main = paste("Top50 Interactors of", input$gene_sel))
        legend(
          x = 0.6, y = -1,
          legend = c(
            input$gene_sel,
            expression(bold('Network Score')~'> 0'),
            expression(bold('Network Score')~'= 0 or Not Available')
          ),
          col = c( "pink","#83C9C8", "#C9E8E7"),
          pch = 21,
          pt.bg = c("pink","#83C9C8", "#C9E8E7"),
          pt.cex = 1,
          cex = 0.7,
          bty = "n",
          xpd = TRUE  # Allow the legend to be drawn outside the plot region
        )
        
        dev.off()  # Close the graphics device
      
    }
  )
  

  
  # Show a popup when user clicks download
  observeEvent(input$downloadData, {
    showModal(modalDialog(
      title = "Select file format",
      selectInput("file_format_gene", "Choose format:", choices = c("Excel (.xlsx)" = "xlsx", "CSV Folder (.zip)" = "csv_zip")),
      footer = tagList(
        modalButton("Cancel"),
        downloadButton("downloadWData", "Download")
      )
    ))
  })
  
  # File Download Handler
  output$downloadWData <- downloadHandler(
    filename = function() {
      basename(get_file_link(input$g_network_tumor, input$data_type_precog, input$g_network_mutated_interactors, 
                             if (input$file_format_gene == "csv_zip") "csv" else "xlsx"))
    },
    content = function(file) {
      req(input$file_format_gene, input$g_network_tumor, input$data_type_precog, input$gene_sel)
      
      # Fetch the correct file (either Excel or pre-zipped CSV)
      file_url <- get_file_link(input$g_network_tumor, input$data_type_precog, input$g_network_mutated_interactors, 
                                if (input$file_format_gene == "csv_zip") "csv" else "xlsx")
      
      # Download the file directly—no need to create ZIPs dynamically!
      download.file(file_url, file, mode = "wb")
    }
  )
  
  
  gene_data <- reactive({
    req(input$gene_sel, input$g_network_tumor, input$data_type_precog)  # Ensure input is provided
    
    data_result <- tryCatch(
      {
        Get_gene_interactors(
          data = gene_interactors, 
          original = data,
          cancer_type = input$g_network_tumor, 
          gene = input$gene_sel, 
          int_type = input$data_type_precog,
          include_mutated = input$g_network_mutated_interactors
        )
      },
      error = function(e) {
        showNotification("Error: Data could not be generated.", type = "error")
        return(NULL)  # Return NULL on error
      }
    )
    
    validate(
      need(!is.null(data_result), "No data available for download.")
    )
    
    return(data_result)
  })
  
  observeEvent(input$downloadGeN, {
    showModal(modalDialog(
      title = "Select file format",
      selectInput("file_format_gene", "Choose format:", choices = c("Excel (.xlsx)" = "xlsx", "CSV (.csv)" = "csv")),
      footer = tagList(
        modalButton("Cancel"),
        downloadButton("downloadGeneData", "Download")
      )
    ))
  })
  
  # Gene Interactors Download Handler
  output$downloadGeneData <- downloadHandler(
    filename = function() {
      if (input$file_format_gene == "csv") {
        paste("Gene_Interactors_", input$g_network_tumor, "_", input$data_type_precog, "_", input$gene_sel, "_", "CSV.zip", sep = "")
      } else {
        paste("Gene_Interactors_", input$g_network_tumor, "_", input$data_type_precog, "_", input$gene_sel, ".xlsx", sep = "")
      }
    },
    content = function(file) {
      data_nodes <- gene_data()$NODES
      data_edges <- gene_data()$EDGES
      
      req(!is.null(data_nodes), !is.null(data_edges))
      
      if (input$file_format_gene == "csv") {
        # Create two separate CSV files
        nodes_file <- file.path(tempdir(), "nodes.csv")
        edges_file <- file.path(tempdir(), "edges.csv")
        
        write.csv(data_nodes, nodes_file, row.names = FALSE)
        write.csv(data_edges, edges_file, row.names = FALSE)
        
        # Zip the two CSVs together for a single download
        zip::zipr(file, c(nodes_file, edges_file))
        
      } else {
        # Create a single Excel file with two sheets
        wb <- createWorkbook()
        addWorksheet(wb, "Nodes")
        addWorksheet(wb, "Edges")
        
        writeData(wb, "Nodes", data_nodes)
        writeData(wb, "Edges", data_edges)
        
        saveWorkbook(wb, file)
      }
    }
  )

  
}

shinyApp(ui = ui, server = server)

