createMainPanel <- function() {
  mainPanel(
    div(class = "main-panel",
        tabsetPanel(
          id = "tabSelected",
          tabPanel("View Dataframe", value = "View Dataframe",
                   DTOutput("data_view")
          ),
          tabPanel("Gene Ranking", value = "Gene Ranking",
                   br(),
                   plotOutput("ranking_plot", height = "700px") %>% withSpinner(color = "#0A9396"), 
                   br(),
                   plotOutput("pan_cancer_gene_position", height = "85px"),
                   br(), br(), br(), br()
          ),
          tabPanel("Common Genes", value = "Common Genes",
                   uiOutput("category_tabs"),
                   DTOutput("extraction_view"),
                   div(style = "display: flex; justify-content: space-evenly;",
                       plotlyOutput("heatmap_output", height = "800px") %>% withSpinner(color = "#0A9396")),
                   div(style = "display: flex; align-items: center; margin-top: 10px;",
                       div(style = "background-color: pink; width: 20px; height: 20px; margin-right: 5px;"),
                       span("Not Present"),
                       div(style = "background-color: #0A9396; width: 20px; height: 20px; margin-left: 20px; margin-right: 5px;"),
                       span("Present"),
                       br(),
                       br(),
                       br(),
                       br()
                   )
          ),
          tabPanel("Network Plot", value = "Network Plot",
                   br(),
                   br(),
                   div(style = "display: flex; justify-content: center; width: 100%;",
                       plotlyOutput("network_plot", height = "600px") %>% withSpinner(color = "#0A9396")),
                   textOutput("top_n_feedback"),
                   br()
          ),
          tabPanel("Gene Network", value = "Gene Network",
                   plotOutput("gene_network", width = "800px", height = "800px") %>% withSpinner(color = "#0A9396"),
                   br(),
                   div(
                     style ="display: flex; align-items: center; margin-top: -40px;",  # Add spacing between the graph and the legend
                     div(style = "background-color: pink; width: 20px; height: 20px; margin-right: 5px; border-radius: 50% ;"),
                     span("Input Gene"),
                     div(style = "background-color: #83C9C8; width: 20px; height: 20px; margin-left: 20px; margin-right: 5px;border-radius: 50% ;"),
                     span("Node with Network Score"),
                     div(style = "background-color: #C9E8E7; width: 20px; height: 20px; margin-left: 20px; margin-right: 5px;border-radius: 50%;"),
                     span("Node with Network Score equal to 0"),
                     br(),br(),br(),br(),
                     )
                   
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
