createMainPanel <- function() {
  mainPanel(
    div(class = "main-panel",
        tabsetPanel(
          id = "tabSelected",
          tabPanel("Introduction", value = "Introduction", 
                   fluidPage(
                     # Dataset explanation retained from original
                     div(style = "font-size: 13px; text-align: justify;",
                         HTML("
             <h4>🧿️ Overview</h4>
               <p><strong>CancerHubs Data Explorer</strong> is a shiny app which provides an interactive interface for exploring results from the <a href='https://github.com/ingmbioinfo/cancerhubs' target='_blank'>CancerHubs project</a>, now extended to include <strong>11 tumour types</strong>.</p>

             <p>The following gene subsets are available for exploration:</p>
             <ul>
               <li><strong>All Genes</strong>: The complete list of genes selected by the CancerHubs framework, scored per tumour, regardless of mutation status or external annotation.</li>
             <li><strong>PRECOG</strong>: Genes annotated by the <a href='https://precog.stanford.edu/' target='_blank'>PRECOG</a> database, reflecting significant prognostic associations.</li>
               <li><strong>Only Mutated</strong>: Genes identified as mutated in the tumour dataset, excluding those in PRECOG set.</li>
             <li><strong>Only PRECOG</strong>: Genes which are significant for PRECOG Z-score that are not found mutated in the dataset.</li>
             </ul>

               <p>All genes are ranked using a <strong>Network Score</strong>, which quantifies how many of their direct interaction partners are mutated within a given tumour type. By integrating protein–protein interaction data from <a href='https://thebiogrid.org/' target='_blank'>BioGRID</a> with tumour-specific mutation profiles, this score highlights genes that are highly connected to dysfunctional or altered pathways, pointing to their potential as central regulators or therapeutic targets in cancer biology.</p>
             "), 
                         hr(),
                         
                         # Feature highlights
                         
                         tags$div(style = "font-size: 13px; text-align: justify;",
                                  
                                  tags$h4("🔍 Features"),
                                  
                                  tags$p("This website allows direct interaction with CancerHubs data through several key tabs:"),
                                  
                                  tags$ul(
                                    
                                    tags$li(
                                      
                                      actionLink("go_df", strong("View Dataframes")), 
                                      
                                        ": Explore pre-processed gene tables for each tumour type. Choose between ",
                                      
                                      em("All Genes"), ", ", em("PRECOG"), ", ", em("Only Mutated"), ", and ", em("Only PRECOG"),
                                      
                                      " subsets. Download filtered data as XLSX or CSV."
                                      
                                    ),
                                    
                                    tags$li(
                                      
                                      actionLink("go_rank", strong("Gene Ranking Analysis")), 
                                      
                                      ": Input a gene symbol to check its rank across cancers based on <strong>Network Score</strong>. Visualise and download the results, including a pan-cancer positioning plot."
                                      
                                    ),
                                    
                                    tags$li(
                                      
                                      actionLink("go_common", strong("Common Genes Explorer")), 
                                      
                                      ": Identify genes that consistently rank in the top N positions across multiple tumours. View results in a dynamic heatmap and export them."
                                      
                                    ),
                                    
                                    tags$li(
                                      
                                      actionLink("go_3d", strong("Network Plot (3D)")), 
                                      
                                      ": Visualise a 3D network of the top-scoring genes in a tumour dataset. Interactions are mapped based on known BioGRID interactions. Node colour, shape, and size encode multiple annotations."
                                      
                                    ),
                                    
                                    tags$li(
                                      
                                      actionLink("go_2d", strong("Gene-Centric Network (2D)")), 
                                      
                                      ": Explore direct interactors of any gene of interest. Visualise up to 50 interactors with igraph-style layout and download both the network image and tables."
                                      
                                    )
                                    
                                  )
                                  
                         ),
                         
                         
                         
                         hr(),
                         
                         div(style = "font-size: 13px; text-align: justify;",
                             HTML("
             <h4>📖 Citation</h4>
             <p>If you use CancerHubs in your research, please cite our paper:</p>
             <p>Ivan Ferrari, Federica De Grossi, Giancarlo Lai, Stefania Oliveto, Giorgia Deroma, Stefano Biffo, Nicola Manfrini</p>
             <p><strong>CancerHubs: a systematic data mining and elaboration approach for identifying novel cancer-related protein interaction hubs</strong></p>
             <p>Briefings in Bioinformatics, Volume 26, Issue 1, January 2025</p>
             "),
                             tags$a(href = "https://doi.org/10.1093/bib/bbae635", "https://doi.org/10.1093/bib/bbae635")  # Corrected outside HTML()
                         ),
                         
                         br(), br()
                         
                     )
                   )
          ),
          
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
                   
                   # Static legend (shape + size)
                   div(style = "display: flex; justify-content: center; gap: 50px; flex-wrap: wrap; align-items: center; font-size: 14px;",
                       
                       # Shape legend
                       div(style = "display: flex; align-items: center;",
                           div(style="width: 20px; height: 20px; border-radius: 50%; background-color: #d4ecf9; border: 1px solid white; margin-right: 5px;"),
                           span("PRECOG (circle)")
                       ),
                       div(style = "display: flex; align-items: center;",
                           div(style="width: 20px; height: 20px; background-color: #d4ecf9; border: 1px solid white; margin-right: 5px;"),
                           span("Non-PRECOG (square)")
                       ),
                       
                       # Size legend
                       div(style = "display: flex; align-items: center; margin-left: 30px;",
                           div(style="width: 20px; height: 20px; border-radius: 50%; background-color: #d4ecf9; border: 1px solid white; margin-right: 5px;"),
                           span("Mutated (large)")
                       ),
                       div(style = "display: flex; align-items: center;",
                           div(style="width: 12px; height: 12px; border-radius: 50%; background-color: #d4ecf9; border: 1px solid white; margin-right: 5px;"),
                           span("Non-mutated (small)")
                       )
                   )
          ),
          tabPanel("Gene Network", value = "Gene Network",
                   plotOutput("gene_network", width = "800px", height = "800px") %>% withSpinner(color = "#0A9396"),
                   br(),
                   div(
                     style ="display: flex; align-items: center; margin-top: -40px;",  # Add spacing between the graph and the legend
                     div(style = "background-color: pink; width: 20px; height: 20px; margin-right: 5px; border-radius: 50% ;"),
                     span("Input Gene"),
                     div(style = "background-color: #83C9C8; width: 20px; height: 20px; margin-left: 20px; margin-right: 5px;border-radius: 50% ;"),
                     span(tags$strong("Network Score > 0")),
                     div(style = "background-color: #C9E8E7; width: 20px; height: 20px; margin-left: 20px; margin-right: 5px;border-radius: 50%;"),
                     span(tags$strong("Network Score = 0 or Not Available")),
                     br(),br(),br(),br(),
                   )
                   
          )
          
        )
    )
  )
}
