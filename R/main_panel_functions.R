createMainPanel <- function() {
  mainPanel(
    div(class = "main-panel",
        tabsetPanel(
          id = "tabSelected",
          tabPanel("View Dataframe", value = "View Dataframe", DTOutput("data_view")),
          tabPanel("Gene Ranking", value = "Gene Ranking", plotOutput("ranking_plot", height = "600px")),
          tabPanel("Common Genes", value = "Common Genes",uiOutput("category_tabs"), DTOutput("extraction_view"),plotlyOutput("heatmap_output",height = "800px")),
          tabPanel("Network Plot", value = "Network Plot",
                   fluidRow(
                     column(3, selectInput("network_tumor", "Select Tumor:", choices = names(data))),
                     column(3, selectInput("network_dataset_type", "Select Dataset Type:", choices = c("All_Genes", "PRECOG", "Non_PRECOG", "Only_PRECOG"))),
                     column(3, selectInput("network_color_by", "Color by:", choices = c("network_score", "precog_metaZ"))),
                     column(3, numericInput("network_top_n", "Number of Top Genes:", value = 10, min = 1)),
                     column(3, checkboxInput("network_mutated_interactors", "Include Only Mutated Interactors", value = TRUE))
                   ),
                   plotlyOutput("network_plot", height = "600px"),
                   br(),
                   plotOutput("network_legend_plot"),
          
          )
        )
    )
  )
}
