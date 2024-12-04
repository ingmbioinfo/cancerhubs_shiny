createSidebar <- function() {
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
          tableOutput("gene_info_table"),
          downloadButton("download_plot", "Download Plot (PDF)"),
          downloadButton("download_ranking_table", "Download Ranking Table (XLSX)")
        ),
        conditionalPanel(
          condition = "input.tabSelected === 'Common Genes'",
          numericInput("num_lines", "Number of Top genes:", value = 50),
          selectInput("selected_dataframe", "Choose Dataframe to View:", 
                      choices = c("All_Genes","PRECOG", "Non_PRECOG", "Only_PRECOG"), 
                      selected = "All_Genes"),
          downloadButton("download_high_res", "Download High-Resolution Heatmap"),
          br(),
          br(),
          numericInput("num_cancers", "Min. Presence in Tumors:", value = 2),
          downloadButton("download_extracted_data", "Download Extracted Data (XLSX)"),
        ),
        conditionalPanel(
          condition = "input.tabSelected === 'Network Plot'",
          h4("Nodes Table"),
          DTOutput("nodes_table"),
          downloadButton("download_network_nodes", "Download Nodes Table (XLSX)"),
          br(), br(),
          h4("Edges Table"),
          DTOutput("edges_table"),
          downloadButton("download_network_edges", "Download Edges Table (XLSX)"),
          
        )
    )
  )
}

