createMainPanel <- function() {
  mainPanel(
    div(class = "main-panel",
        tabsetPanel(
          id = "tabSelected",
          tabPanel("Introduction", value = "Introduction", 
                   fluidPage(
                     # Main heading and welcome
                     div(style = "text-align: center; font-size: 15px;",
                         HTML("<h2><strong>CancerHubs Data Explorer</strong></h2>
              <p>Welcome to the <strong>CancerHubs Data Explorer</strong>! This Shiny application provides an interactive interface for exploring results from the <a href='https://github.com/ingmbioinfo/cancerhubs' target='_blank'>CancerHubs project</a>, including ranked gene data across tumor types, network visualisations, and shared hubs.</p>")
                     ),
                     
                     hr(),
                     
                     # Dataset explanation retained from original
                     div(style = "font-size: 15px; text-align: justify;",
                         HTML("
             <h3>🧬 Data Overview</h3>
             <p>The CancerHubs Explorer currently includes data from <strong>11 tumor types</strong>. The datasets will be regularly updated, and future releases will broaden the scope to include additional tumor types and omics layers.</p>

             <p>The application includes the following gene subsets for exploration:</p>
             <ul>
             <li><strong>All Genes</strong>: Complete list of scored genes per tumor, regardless of mutation or external annotation.</li>
             <li><strong>PRECOG</strong>: Genes annotated by the <a href='https://precog.stanford.edu/' target='_blank'>PRECOG</a> database, reflecting known prognostic associations.</li>
             <li><strong>Only Mutated</strong>: Genes identified as mutated in each tumor dataset, excluding those in PRECOG.</li>
             <li><strong>Only PRECOG</strong>: Genes from the PRECOG database that are not found mutated in the dataset.</li>
             </ul>

             <p>All genes are ranked using a <strong>Network Score</strong>, which captures their topological relevance within interaction networks derived from <a href='https://thebiogrid.org/' target='_blank'>BioGRID</a>. This prioritization helps spotlight genes that may play central roles in tumor biology.</p>
             "), 
                         hr(),
                         
                         # Feature highlights
                         div(style = "font-size: 15px; text-align: justify;",
                             HTML("
             <h3>🔍 App Features</h3>
             <p>This website allows direct interaction with CancerHubs data through several key tabs:</p>
             <ul>
             <li><strong>View Dataframes</strong>: Explore pre-processed gene tables for each tumor type. Choose between <em>All Genes</em>, <em>PRECOG</em>, <em>Only Mutated</em>, and <em>Only PRECOG</em> subsets. Download filtered data as Excel.</li>
             <li><strong>Gene Ranking Analysis</strong>: Input a gene symbol to check its rank across cancers based on Network Score. Visualise and download the results, including a pan-cancer positioning plot.</li>
             <li><strong>Common Genes Explorer</strong>: Identify genes that consistently rank in the top N positions across multiple tumors. View results in a dynamic heatmap and export them.</li>
             <li><strong>Network Plot (3D)</strong>: Visualise a 3D network of the top-scoring genes in a tumor dataset. Interactions are mapped based on known BioGRID interactions. Node color, shape, and size encode multiple annotations.</li>
             <li><strong>Gene-Centric Network (2D)</strong>: Explore direct interactors of any gene of interest. Visualise up to 50 interactors with igraph-style layout and download both the network image and tables.</li>
             </ul>
              ")
                         ),
                         
                         hr(),
                         
                         div(style = "font-size: 15px; text-align: justify;",
                             HTML("
             <h3>📖 Citation</h3>
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
                     span("Network Score > 0"),
                     div(style = "background-color: #C9E8E7; width: 20px; height: 20px; margin-left: 20px; margin-right: 5px;border-radius: 50%;"),
                     span("Network Score = 0 or Not Available"),
                     br(),br(),br(),br(),
                   )
                   
          )
          
        )
    )
  )
}