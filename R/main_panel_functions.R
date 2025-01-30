createMainPanel <- function() {
  mainPanel(
    div(class = "main-panel",
        tabsetPanel(
          id = "tabSelected",
          tabPanel("View Dataframe", value = "View Dataframe",
                   DTOutput("data_view")
          ),
          tabPanel("Gene Ranking", value = "Gene Ranking",
                   plotOutput("ranking_plot", height = "570px"), 
                   plotOutput("pan_cancer_gene_position", height = "85px")
          ),
          tabPanel("Common Genes", value = "Common Genes",
                   uiOutput("category_tabs"),
                   DTOutput("extraction_view"),
                   plotlyOutput("heatmap_output", height = "800px"),
                   div(style = "display: flex; align-items: center; margin-top: 10px;",
                       div(style = "background-color: pink; width: 20px; height: 20px; margin-right: 5px;"),
                       span("Not Present"),
                       div(style = "background-color: #0A9396; width: 20px; height: 20px; margin-left: 20px; margin-right: 5px;"),
                       span("Present")
                   )
          ),
          tabPanel("Network Plot", value = "Network Plot",
                   fluidRow(
                     column(3, selectInput("network_tumor", "Select Tumor:", choices = names(data))),
                     column(3, selectInput("network_dataset_type", "Select Dataset Type:", choices = c("All_Genes", "PRECOG", "Non_PRECOG", "Only_PRECOG"))),
                     column(3, selectInput("network_color_by", "Color by:", choices = c("network_score", "precog_metaZ"))),
                     column(3, numericInput("network_top_n", "Number of Top Genes:", value = 10, min = 1)),
                     column(3, checkboxInput("network_mutated_interactors", "Include Only Mutated Interactors", value = TRUE))
                   ),
                   plotlyOutput("network_plot", height = "600px"),
                   br()
          ),
          tabPanel("About Us", value = "About Us",
                   h3("Contact"),
                   p("For questions or support, please contact:"),
                   tags$ul(
                     tags$li("manfrini@ingm.org"),
                     tags$li("ferrari@ingm.org"),
                     tags$li("arsuffi@ingm.org")
                   ),
                   h3("Citation"),
                   p("If you use CancerHubs in your research, please cite our paper:"),
                   p(em("Ivan Ferrari, Federica De Grossi, Giancarlo Lai, Stefania Oliveto, Giorgia Deroma, Stefano Biffo, Nicola Manfrini,")),
                   p(strong("CancerHubs: a systematic data mining and elaboration approach for identifying novel cancer-related protein interaction hubs,")),
                   p("Briefings in Bioinformatics, Volume 26, Issue 1, January 2025, ",
                     tags$a(href = "https://doi.org/10.1093/bib/bbae635", "https://doi.org/10.1093/bib/bbae635")),
                   h3("License"),
                   p("This project is licensed under the MIT License. Copyright (c) 2024 National Istitute of Molecular Genetics (INGM)."),
                   h3("Funding"),
                   p("This research was funded by Associazione Italiana per la Ricerca sul Cancro (AIRC), under MFAG 2021 ID 26178 project to Nicola Manfrini.")
          )
        )
    )
  )
}
