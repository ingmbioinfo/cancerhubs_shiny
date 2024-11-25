library(shiny)
library(ggplot2)
library(openxlsx)
library(DT)

# Load the RDS file
data <- readRDS("all_results")

# Define the CancerHubs-inspired color palette for styling
cancerhubs_style <- list(
  background = "#f5f9fc",
  sidebar_bg = "#eaf6fc",
  primary_text = "#1B4F72",
  accent = "#28A3E0",
  header_text = "#17BEBB",
  button_bg = "#0A9396"
)

# UI components
createSidebar <- function() {
  sidebarPanel(
    div(class = "sidebar",
        conditionalPanel(
          condition = "input.tabSelected === 'View Dataframe'",
          selectInput("cancer_type_df", "Select Cancer Type:", choices = names(data)),
          selectInput("dataframe", "Select Dataframe:",
                      choices = c("All Genes" = "All_Genes", 
                                  "PRECOG" = "PRECOG", 
                                  "Non PRECOG" = "Non_PRECOG")),
          downloadButton("download_dataframe", "Download Dataframe (XLSX)")
        ),
        conditionalPanel(
          condition = "input.tabSelected === 'Gene Ranking'",
          textInput("gene", "Enter Gene Name:", value = "TP53"),
          selectInput("dataframe_subset", "Select Dataframe Subset:",
                      choices = c("All Genes" = "All_Genes", 
                                  "PRECOG" = "PRECOG", 
                                  "Non PRECOG" = "Non_PRECOG")),
          DTOutput("ranking_table"),
          tableOutput("gene_info_table"),
          downloadButton("download_plot", "Download Plot (PDF)"),
          downloadButton("download_ranking_table", "Download Ranking Table (XLSX)")
        )
    )
  )
}

createMainPanel <- function() {
  mainPanel(
    div(class = "main-panel",
        tabsetPanel(
          id = "tabSelected",
          tabPanel(
            "View Dataframe", value = "View Dataframe", 
            DTOutput("data_view")
          ),
          tabPanel(
            "Gene Ranking", value = "Gene Ranking",
            plotOutput("ranking_plot", height = "600px")
          )
        )
    )
  )
}

# Define UI
ui <- fluidPage(
  tags$head(
    tags$style(HTML(sprintf("\n      body {\n        background-color: %s;\n        font-family: 'Arial', sans-serif;\n      }\n      .title-panel {\n        text-align: center;\n        color: %s;\n        font-weight: bold;\n      }\n      .sidebar {\n        background-color: %s;\n        border-radius: 10px;\n        padding: 15px;\n        box-shadow: 2px 2px 5px rgba(0,0,0,0.1);\n      }\n      .main-panel {\n        border-radius: 10px;\n        padding: 20px;\n        background-color: white;\n        box-shadow: 2px 2px 5px rgba(0,0,0,0.1);\n      }\n      table {\n        width: 100%%;\n        margin-top: 10px;\n      }\n      th {\n        background-color: %s;\n        color: white;\n      }\n    ",
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
    data[[input$cancer_type_df]][[input$dataframe]]
  })
  
  # Display the selected dataframe for "View Dataframe" with interactive features
  output$data_view <- renderDT({
    datatable(selected_data_df(), options = list(pageLength = 10, scrollX = TRUE))
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
  get_gene_ranking <- reactive({
    req(input$gene, input$dataframe_subset)
    gene_name <- input$gene
    subset_df <- input$dataframe_subset
    
    # Initialize an empty dataframe to store rankings
    rankings <- data.frame(
      Tumor = character(),
      Rank = numeric(),
      TotalGenes = numeric(),
      PrecogMetaZ = numeric(),
      MutationStatus = character(),
      stringsAsFactors = FALSE
    )
    
    # Iterate through each cancer type
    for (cancer_type in names(data)) {
      df <- data[[cancer_type]][[subset_df]]
      
      # Check if the gene exists in the dataframe
      if (gene_name %in% df$gene_list) {
        df <- df[order(-df$network_score, na.last = TRUE), ]
        rank <- which(df$gene_list == gene_name)
        precog_metaZ <- df$precog_metaZ[rank]
        mutation_status <- df$mutation[rank]
        total_genes <- nrow(df)
        
        rankings <- rbind(rankings, data.frame(
          Tumor = cancer_type,
          Rank = rank,
          TotalGenes = total_genes,
          PrecogMetaZ = precog_metaZ,
          MutationStatus = mutation_status
        ))
      }
    }
    # Order rankings by rank for y-axis reordering
    rankings <- rankings[order(rankings$Rank), ]
    rankings
  })
  
  # Function to create the ranking plot
  create_ranking_plot <- function(rankings) {
    if (nrow(rankings) == 0) {
      plot(1, type = "n", xlab = "", ylab = "", main = "Gene not found in any tumor type")
    } else {
      # Add a column with rank/total genes information
      rankings$RankOutOf <- paste0(rankings$Rank, " / ", rankings$TotalGenes)
      # Create the plot
      ggplot(rankings, aes(x = -Rank, y = reorder(Tumor, -Rank), color = Tumor)) +
        geom_point(size = 7, shape = 16) +
        geom_text(aes(label = RankOutOf), hjust = -0.3, vjust = -0.5, size = 6, show.legend = FALSE) +
        scale_x_reverse(expand = expansion(mult = c(0.05, 0.4))) +
        labs(
          title = paste("Ranking of", input$gene, "in", gsub("_", " ", input$dataframe_subset)),
          x = "Rank (1 = Top Importance)",
          y = "Tumor Type",
          color = "Tumor Type"
        ) +
        theme_classic() +
        theme(
          axis.text.y = element_text(size = 12),
          axis.text.x = element_text(size = 12),
          plot.title = element_text(hjust = 0.5, size = 14),
          panel.grid.major = element_line(color = "#dfe6ec"),
          legend.position = "bottom",
          plot.margin = margin(10, 40, 10, 10) # Increase right margin to avoid truncation
        ) +
        guides(color = guide_legend(override.aes = list(size = 5, shape = 16)))
    }
  }
  
  # Render the plot for gene rankings
  output$ranking_plot <- renderPlot({
    rankings <- get_gene_ranking()
    create_ranking_plot(rankings)
  })
  
  # Render the table for gene rankings
  output$ranking_table <- renderDT({
    rankings <- get_gene_ranking()
    datatable(rankings, options = list(pageLength = 5, scrollX = TRUE), rownames = FALSE)
  })
  
  # Provide download for the plot as PDF
  output$download_plot <- downloadHandler(
    filename = function() {
      paste(input$gene, "_ranking_plot.pdf", sep = "")
    },
    content = function(file) {
      pdf(file, width = 10, height = 7)
      rankings <- get_gene_ranking()
      print(create_ranking_plot(rankings))
      dev.off()
    }
  )
  
  # Provide download for the ranking table as XLSX
  output$download_ranking_table <- downloadHandler(
    filename = function() {
      paste(input$gene, "_ranking_table.xlsx", sep = "")
    },
    content = function(file) {
      write.xlsx(get_gene_ranking(), file)
    }
  )
}

shinyApp(ui = ui, server = server)