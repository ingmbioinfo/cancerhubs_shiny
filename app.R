library(shiny)
library(ggplot2)
library(openxlsx)
library(DT)

# Load the RDS file
data <- readRDS(url("https://github.com/ingmbioinfo/cancerhubs/raw/refs/heads/main/result/all_results.rds"))

# Source the styles and functions from the R subdirectory
source("R/styles.R")  # Define cancerhubs_style
source("R/sidebar_functions.R")
source("R/main_panel_functions.R")
source("R/gene_ranking_functions.R")
source("R/plot_functions.R")

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
}

shinyApp(ui = ui, server = server)
