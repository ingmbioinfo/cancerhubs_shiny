# Load necessary libraries
library(shiny)        # For creating interactive web applications
library(ggplot2)      # For data visualization and plots
library(openxlsx)     # For reading and writing Excel files
library(DT)           # For interactive tables

# Load the RDS file containing data
# Assumes "all_results" is a list with data frames for different cancer types
data <- readRDS("all_results")

# Define the CancerHubs-inspired color palette for styling the UI
cancerhubs_style <- list(
  background = "#f5f9fc",          # Background color for the body
  sidebar_bg = "#eaf6fc",          # Background color for the sidebar
  primary_text = "#1B4F72",        # Primary text color
  accent = "#28A3E0",              # Accent color for UI elements
  header_text = "#17BEBB",         # Header text color
  button_bg = "#0A9396"            # Button background color
)

# Function to create the sidebar UI components
createSidebar <- function() {
  sidebarPanel(
    div(class = "sidebar",
        # Conditional panel for "View Dataframe" tab
        conditionalPanel(
          condition = "input.tabSelected === 'View Dataframe'",
          selectInput("cancer_type_df", "Select Cancer Type:", choices = names(data)),  # Dropdown to select cancer type
          selectInput("dataframe", "Select Dataframe:",                                    # Dropdown to select dataframe type
                      choices = c("All Genes" = "All_Genes", 
                                  "PRECOG" = "PRECOG", 
                                  "Non PRECOG" = "Non_PRECOG")),
          downloadButton("download_dataframe", "Download Dataframe (XLSX)")                # Button to download dataframe
        ),
        # Conditional panel for "Gene Ranking" tab
        conditionalPanel(
          condition = "input.tabSelected === 'Gene Ranking'",
          textInput("gene", "Enter Gene Name:", value = "TP53"),                          # Text input for gene name
          selectInput("dataframe_subset", "Select Dataframe Subset:",                      # Dropdown to select dataframe subset
                      choices = c("All Genes" = "All_Genes", 
                                  "PRECOG" = "PRECOG", 
                                  "Non PRECOG" = "Non_PRECOG")),
          DTOutput("ranking_table"),                                                        # Output for ranking table
          tableOutput("gene_info_table"),                                                   # Output for gene info table
          downloadButton("download_plot", "Download Plot (PDF)"),                          # Button to download plot
          downloadButton("download_ranking_table", "Download Ranking Table (XLSX)")        # Button to download ranking table
        )
    )
  )
}

# Function to create the main panel UI components
createMainPanel <- function() {
  mainPanel(
    div(class = "main-panel",
        tabsetPanel(
          id = "tabSelected",
          # Tab for viewing dataframe
          tabPanel(
            "View Dataframe", value = "View Dataframe", 
            DTOutput("data_view")  # Output for viewing dataframe
          ),
          # Tab for gene ranking
          tabPanel(
            "Gene Ranking", value = "Gene Ranking",
            plotOutput("ranking_plot", height = "600px")  # Output for ranking plot
          )
        )
    )
  )
}

# Define the UI for the Shiny app
ui <- fluidPage(
  # Include custom CSS styles
  tags$head(
    tags$style(HTML(sprintf("\n      body {\n        background-color: %s;\n        font-family: 'Arial', sans-serif;\n      }\n      .title-panel {\n        text-align: center;\n        color: %s;\n        font-weight: bold;\n      }\n      .sidebar {\n        background-color: %s;\n        border-radius: 10px;\n        padding: 15px;\n        box-shadow: 2px 2px 5px rgba(0,0,0,0.1);\n      }\n      .main-panel {\n        border-radius: 10px;\n        padding: 20px;\n        background-color: white;\n        box-shadow: 2px 2px 5px rgba(0,0,0,0.1);\n      }\n      table {\n        width: 100%%;\n        margin-top: 10px;\n      }\n      th {\n        background-color: %s;\n        color: white;\n      }\n    ",
                            cancerhubs_style$background,
                            cancerhubs_style$primary_text,
                            cancerhubs_style$sidebar_bg,
                            cancerhubs_style$button_bg
    )))
  ),
  
  # Title panel for the app
  titlePanel(
    div(class = "title-panel", "CancerHubs Data Explorer")
  ),
  
  # Layout with sidebar and main panel
  sidebarLayout(
    createSidebar(),
    createMainPanel()
  )
)

# Define server logic for the Shiny app
server <- function(input, output, session) {
  
  # Reactive function to fetch the selected dataframe based on user input
  selected_data_df <- reactive({
    req(input$cancer_type_df, input$dataframe)  # Ensure both inputs are available
    data[[input$cancer_type_df]][[input$dataframe]]
  })
  
  # Render the selected dataframe for "View Dataframe" tab
  output$data_view <- renderDT({
    datatable(selected_data_df(), options = list(pageLength = 10, scrollX = TRUE))  # Display with pagination and horizontal scrolling
  })
  
  # Download handler to provide the selected dataframe as an XLSX file
  output$download_dataframe <- downloadHandler(
    filename = function() {
      paste(input$cancer_type_df, '_', input$dataframe, ".xlsx", sep = "")  # Filename based on selected inputs
    },
    content = function(file) {
      write.xlsx(selected_data_df(), file)  # Write the dataframe to the specified file
    }
  )
  
  # Reactive function to calculate rankings for the selected gene
  get_gene_ranking <- reactive({
    req(input$gene, input$dataframe_subset)  # Ensure both inputs are available
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
    
    # Iterate through each cancer type to calculate rankings
    for (cancer_type in names(data)) {
      df <- data[[cancer_type]][[subset_df]]
      
      # Check if the gene exists in the dataframe
      if (gene_name %in% df$gene_list) {
        df <- df[order(-df$network_score, na.last = TRUE), ]  # Sort by network score in descending order
        rank <- which(df$gene_list == gene_name)  # Find rank of the gene
        precog_metaZ <- df$precog_metaZ[rank]  # Get precog_metaZ value for the gene
        mutation_status <- df$mutation[rank]  # Get mutation status for the gene
        total_genes <- nrow(df)  # Get total number of genes
        
        # Add the gene ranking information to the dataframe
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
      # If no rankings found, display a blank plot with a message
      plot(1, type = "n", xlab = "", ylab = "", main = "Gene not found in any tumor type")
    } else {
      # Add a column with rank/total genes information
      rankings$RankOutOf <- paste0(rankings$Rank, " / ", rankings$TotalGenes)
      # Create the ranking plot using ggplot2
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
    create_ranking_plot(rankings)  # Generate and render the plot
  })
  
  # Render the table for gene rankings
  output$ranking_table <- renderDT({
    rankings <- get_gene_ranking()
    datatable(rankings, options = list(pageLength = 5, scrollX = TRUE), rownames = FALSE)  # Display the ranking table
  })
  
  # Provide download for the plot as PDF
  output$download_plot <- downloadHandler(
    filename = function() {
      paste(input$gene, "_ranking_plot.pdf", sep = "")  # Filename based on selected gene
    },
    content = function(file) {
      pdf(file, width = 10, height = 7)  # Create a PDF device
      rankings <- get_gene_ranking()
      print(create_ranking_plot(rankings))  # Print the plot to the PDF
      dev.off()  # Close the PDF device
    }
  )
  
  # Provide download for the ranking table as XLSX
  output$download_ranking_table <- downloadHandler(
    filename = function() {
      paste(input$gene, "_ranking_table.xlsx", sep = "")  # Filename based on selected gene
    },
    content = function(file) {
      write.xlsx(get_gene_ranking(), file)  # Write the ranking table to the specified file
    }
  )
}

# Create the Shiny application
shinyApp(ui = ui, server = server)
