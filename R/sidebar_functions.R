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
          downloadButton("download_ranking_table", "Download Ranking Table (XLSX)"),
          downloadButton("download_pan_cancer", "Download Pan-Cancer Ranking (XLSX)")
        ),
        conditionalPanel(
          condition = "input.tabSelected === 'Common Genes'",
          h4("Parameters selection"),
          p('The selection feature enables you to identify the number of genes shared across various tumors among the "TOP" ranking genes, based on their Network score.'),
          p ('Additionally, you can apply a cut-off to select genes that appear in the TOP positions of (at least) the number of  cancers specified in "Minimum Presence in Tumors".'),
          numericInput("num_lines", "Number of TOP genes:", value = 50),
          selectInput("selected_dataframe", "Choose Dataframe to View:", 
                      choices = c("All_Genes","PRECOG", "Non_PRECOG", "Only_PRECOG"), 
                      selected = "All_Genes"),
          numericInput("num_cancers", "Min. Presence in Tumors:", value = 2),
          br(),
          downloadButton("download_extracted_data", "Download Extracted Data (XLSX)")
        ),
        conditionalPanel(
          condition = "input.tabSelected === 'Network Plot'",
          h4("Parameters selection"),
          p('This section allows you to display in an interactive way the network of interactions that exist among the highest network-scoring genes in your interest tumor. The colors can be set to show the network scores or the precog metaZ score.'),
          selectInput("network_tumor", "Select Tumor:", choices = names(data)),
          selectInput("network_dataset_type", "Select Dataset Type:", choices = c("All_Genes", "PRECOG", "Non_PRECOG", "Only_PRECOG")),
          selectInput("network_color_by", "Color by:", choices = c("network_score", "precog_metaZ")),
          numericInput("network_top_n", "Number of Top Genes:", value = 10, min = 1, max = 50),
          checkboxInput("network_mutated_interactors", "Include Only Mutated Interactors", value = TRUE),
          br(),
          h4("Downloads"),
          p('Here you can download your selected data, for the download of the image look at the top-right corner of the interactive network'),
          br(),
          downloadButton("download_network_edges", "Download Edges Table (XLSX)"),
          br(),
          downloadButton("download_network_nodes", "Download Nodes Table (XLSX)")
        ),
        conditionalPanel(
          condition = "input.tabSelected === 'Gene Network'", 
          h4("Parameters selection"), 
          p('In this panel you can search your interest gene and see up to 50 of its interactors selected, if possible, on the basis of their Network Score.     
              This is not always feasible because not all the interactors are present in the relevant genes identified by Cancerhubs, and so, they do not have the score. If genes with no network score are present in the top 50 their presence does NOT mean they are more meaningful.'),
          br(),
          p('Upon selection you can also see the totality of interactions among the shown genes.'),
          selectInput("network_tumor", "Select Tumor:", choices = names(data)),
          selectInput("data_type_precog", "Select Dataset Type:", choices = c("ALL","Only MUTATED", "Only PRECOG")),
          textInput("gene_sel", "Enter Gene Name:", value = "TP53"),
          checkboxInput("g_network_mutated_interactors", "Include Only Mutated Interactors", value = TRUE),
          checkboxInput("cross", "Show all the interactions", value = FALSE),
          br(),
          h4("Downloads"), 
          p('Here you can download the network plot but also the whole dataset of interactions for ALL genes based on your "Select Tumor", "Select Dataset Type", and "Include Only Mutated Interactors" choices'), # Add the formal text
          br(),
          downloadButton("downloadData", "Download Tables (XLSX)"),
          downloadButton("downloadGeneNetwork", "Download Network (PDF)")
        ),
        conditionalPanel(
          condition = "input.tabSelected === 'About Us'",
          div(
            class = "logo-container",
            style = "text-align: center; margin: 10px;",
            img(src = "cancerhubs_logo.png", height = "250px", style = "max-width: 100%;", alt = "CancerHubs Logo"),
            br(),
            h4(style = "text-align: center; color: #1B4F72; font-weight: bold; margin-top: 20px;", "RELATED LINKS "),
            tags$ul(
              style = "list-style-type: none; padding: 0; text-align: center;",
              tags$li(tags$a(href = "https://academic.oup.com/bib/article/26/1/bbae635/7918695", target = "_blank", 
                             style = "color: #0073e6; text-decoration: none; font-size: 14px;", "CancerHubs paper on Briefings in Bioinformatics")),
              tags$li(tags$a(href = "https://github.com/ingmbioinfo/cancerhubs", target = "_blank", 
                             style = "color: #0073e6; text-decoration: none; font-size: 14px;", "Updated CancerHubs Directory")),
              tags$li(tags$a(href = "https://github.com/ingmbioinfo/cancerhubs_shiny", target = "_blank", 
                             style = "color: #0073e6; text-decoration: none; font-size: 14px;", "Updated App Directory")),
              tags$li(tags$a(href = "https://github.com/ingmbioinfo/cancerhubs_paper", target = "_blank", 
                             style = "color: #0073e6; text-decoration: none; font-size: 14px;", "CancerHubs Directory as Published in the Paper"))
            )
          )
        )
    )
  )
}
