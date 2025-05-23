createSidebar <- function() {
  sidebarPanel(
    div(class = "sidebar",conditionalPanel(
      condition = "input.tabSelected === 'Introduction'",
      div(
        class = "logo-container",
        style = "margin: 10px;",
        
        # Logo
        div(style = "text-align: center;",
            img(src = "cancerhubs_logo.png", height = "250px", style = "max-width: 100%;", alt = "CancerHubs Logo")
        ),
        
        # CONTACT INFO
        div(style = "font-size: 13px; text-align: justify;",
            h4(style = "color: black; font-weight: bold; margin-top: 20px;", "Contact Info"),
            p("For questions or support, please contact:"),
            tags$ul( 
              tags$li("manfrini@ingm.org"),
              tags$li("ferrari@ingm.org"),
              tags$li("arsuffi@ingm.org"))
        ),
        
        # RELATED LINKS
        div(style = "font-size: 13px; text-align: justify;",
            h4(style = "color: black; font-weight: bold; margin-top: 20px;", "Related Links"),
            tags$ul(style = "list-style: none; padding-left: 0;",
                    tags$li(tags$a(href = "https://academic.oup.com/bib/article/26/1/bbae635/7918695", target = "_blank", 
                                   style = "color: #0073e6; text-decoration: none;", 
                                   "CancerHubs paper on Briefings in Bioinformatics")),
                    tags$li(tags$a(href = "https://github.com/ingmbioinfo/cancerhubs", target = "_blank", 
                                   style = "color: #0073e6; text-decoration: none;", 
                                   "Updated CancerHubs Directory")),
                    tags$li(tags$a(href = "https://github.com/ingmbioinfo/cancerhubs_shiny", target = "_blank", 
                                   style = "color: #0073e6; text-decoration: none;", 
                                   "Updated App Directory")),
                    tags$li(tags$a(href = "https://github.com/ingmbioinfo/cancerhubs_paper", target = "_blank", 
                                   style = "color: #0073e6; text-decoration: none;", 
                                   "CancerHubs Directory as Published in the Paper"))
            )
        ),
        
        # LICENSE
        div(style = "font-size: 13px; text-align: justify;",
            h4(style = "color: black; font-weight: bold; margin-top: 20px;", "License"),
            p("This project is licensed under the MIT License. Copyright (c) 2024 National Institute of Molecular Genetics (INGM).")
        ),
        
        # FUNDING
        div(style = "font-size: 13px; text-align: justify;",
            h4(style = "color: black; font-weight: bold; margin-top: 20px;", "Funding"),
            p("This research was funded by Associazione Italiana per la Ricerca sul Cancro (AIRC), under MFAG 2021 ID 26178 project to Nicola Manfrini.")
        )
      )
      
      
    ),
        conditionalPanel(
          condition = "input.tabSelected === 'View Dataframe'",
          h4(tags$span(style="font-weight: bold", "View Dataframe")),
          HTML("
  <div style='font-size: 13px;'>
    <p>In this section, you can explore the original datasets used throughout the CancerHubs analysis.</p>
    <p>You can use this panel to:</p>
    <ul>
      <li>Select tumour-specific datasets</li>
      <li>Choose dataset type <em>(e.g.PRECOG, see Introduction for details)</em></li>
      <li>Interactively explore gene-level information</li>
      <li>Download complete tables for external analysis</li>
    </ul>
  </div>
"),
          br(),
          selectInput("cancer_type_df", "Select Tumor:", choices = names(data)),
          selectInput("dataframe", "Select Dataset Type:",
                      choices = c("All Genes" = "All_Genes", 
                                  "PRECOG (Mutated or Not)" = "PRECOG", 
                                  "Only MUTATED (Not Precog)" = "Non_PRECOG",
                                  "Only PRECOG (Not Mutated)" = "Only_PRECOG")),
          actionButton("downloadBtn", "Download Dataframe"),
          br(), br(), br()
        ),
        conditionalPanel(
          condition = "input.tabSelected === 'Gene Ranking'",
          h4(tags$span(style="font-weight: bold", "Gene Ranking")),
          HTML("
  <div style='font-size: 13px;'>
    <p>This panel allows you to investigate the rank of any gene of interest across all tumour types available in the CancerHubs dataset.</p>

    <p>Each gene is ranked within each tumour type according to its <strong>Network Score</strong>, reflecting how central and biologically relevant it is, based on its interactions with other genes in that specific dataset.</p>

    <p>You can view:</p>
    <ul>
      <li>A plot showing the gene's rank (and its percentile) across selected tumour types</li>
      <li>The <strong>Pan-Cancer Score</strong>, summarising the ranks across all tumours</li>
    </ul>

    <p>All plots and tables can be downloaded for further use.</p>
  </div>
"),
          br(),
          textInput("gene", "Enter Gene Name:", value = "TP53"),
          selectInput("dataframe_subset", "Select Dataset Type:",
                      choices = c("All Genes" = "All_Genes", 
                                  "PRECOG (Mutated or Not)" = "PRECOG", 
                                  "Only MUTATED (Not Precog)" = "Non_PRECOG",
                                  "Only PRECOG (Not Mutated)" = "Only_PRECOG")),
          DTOutput("ranking_table"),
          tableOutput("gene_info_table"),
          downloadButton("download_plot", "Download Plot (PDF)"),
          actionButton("downloadRnk", "Download Ranking Table"),
          actionButton("downloadPCR", "Download Pan-Cancer Rankings"),
        ),
        conditionalPanel(
          condition = "input.tabSelected === 'Common Genes'",
          h4(tags$span(style="font-weight: bold", "Common Genes")),
          HTML("
  <div style='font-size: 13px;'>
    <p>This panel helps identify genes that are ranked among the most relevant (Top), on the basis of their Network Score, across multiple tumour types.</p>

    <p>Genes are selected based on their <strong>Network Score</strong>, which reflects their importance in tumour-specific interaction networks.</p>

    <p>By adjusting the parameters, you can:</p>
    <ul>
      <li>Select how many <strong>top-ranking</strong> genes to consider from each tumour type</li>
      <li>Set a threshold for how many <strong>tumors</strong> a gene must appear in to be included</li>
    </ul>

    <p>The output includes:</p>
    <ul>
      <li>A downloadable <strong>table</strong> listing the selected genes and the tumour types in which they recur</li>
      <li>An interactive <strong>heatmap</strong> showing gene presence across tumours (for the image download click on the top-rigth corner of the plot)* </li>
    </ul>

    <p>*The number of top genes selected also determines the number of rows in this heatmap. </p>
  </div>
"),
          br(),
          numericInput("num_lines", "Number of TOP genes:", value = 50),
          selectInput("selected_dataframe", "Select Dataset Type:", 
                      choices = c("All Genes" = "All_Genes", 
                                  "PRECOG (Mutated or Not)" = "PRECOG", 
                                  "Only MUTATED (Not Precog)" = "Non_PRECOG",
                                  "Only PRECOG (Not Mutated)" = "Only_PRECOG"), 
                      selected = "All_Genes"),
          numericInput("num_cancers", "Min. Presence in Tumors:", value = 2),
          br(),
          actionButton("downloadCmG", "Download Common Genes Data") 
        ),
        conditionalPanel(
          condition = "input.tabSelected === 'Network Plot'",
          h4(tags$span(style="font-weight: bold", "Network Plot")),
          HTML("
  <div style='font-size: 13px;'>
    <p>This panel displays an interactive network of the top-ranking genes (based on <strong>Network Score</strong>) for a selected tumour type.</p>

    <p>Each node represents a gene, and edges indicate known interactions among the selected top genes. 
    <p>By adjusting the parameters, you can:</p>
    <ul>
      <li>Choose the number of <strong>top genes</strong> to visualise</li>
      <li>Restrict nodes to <strong>mutated interactors</strong> only</li>
      <li>Switch the coloring of nodes to show their Network Score or their <strong>PRECOG metaZ</strong></li>
    </ul>

    <p>All network data — including the nodes and their connections — can be downloaded as Excel tables. For image download, use the toolbar in the top-right corner of the network panel.</p>
  </div>
"),
          br(),
          selectInput("network_tumor", "Select Tumor:", choices = names(data)),
          selectInput("network_dataset_type", "Select Dataset Type:",  choices = c("All Genes" = "All_Genes", "PRECOG (Mutated or Not)" = "PRECOG",  "Only MUTATED (Not Precog)" = "Non_PRECOG","Only PRECOG (not Mutated)" = "Only_PRECOG")),
          selectInput("network_color_by", "Color by:", choices = c("network_score", "precog_metaZ")),
          numericInput("network_top_n", "Number of Top Genes:", value = 10, min = 1, max = 50),
          checkboxInput("network_mutated_interactors", "Include Only Mutated Interactors", value = TRUE),
          br(),
          actionButton("downloadNtP", "Download Network Data"),  
        ),
        conditionalPanel(
          condition = "input.tabSelected === 'Gene Network'", 
          h4(tags$span(style="font-weight: bold", "Gene Network")), 
          HTML("
  <div style='font-size: 13px;'>
    <p>This panel allows you to explore the interaction partners of a specific gene of interest, selected from the CancerHubs dataset.</p>

    <p>The central input genes are selected through the Select Dataset dropdown, and are sourced from the already established CancerHubs categories. 
    <br>Up to <strong>50 interactors</strong> are shown, prioritised — when possible — by <strong>Network Score</strong>. Interactors without scores are displayed only if no ranked alternatives are available.
    These interactors are not relevant to CancerHubs nor found in the previously displayed tables. 
    <br>In the downloadable tables all the interactors are included, whether ranked or not. </p>
     
     <p>The option to include <strong>Only Mutated interactors</strong> specifically refers to interactors, not to the central input gene. </p>

    <p>Depending on the dataset category selected:</p>
    <ul>
      <li>In <strong>All Genes</strong> and <strong>Only Mutated</strong>, interactors are consistent with the initial raw tables (check 'View Dataframe') </li>
      <li>In <strong>PRECOG</strong> and <strong>Only PRECOG</strong>, gene's interactors must be PRECOG genes</li>
    </ul>

    <p>You can also enable cross-connections among interactors to show shared neighbours.</p>
  </div>
"),
          
          br(),
          selectInput("g_network_tumor", "Select Tumor:", choices = names(data)),
          selectInput("data_type_precog", "Select Dataset Type:", choices = c("All Genes", "PRECOG (Mutated or Not)","Only MUTATED (Not Precog)", "Only PRECOG (Not Mutated)")),
          textInput("gene_sel", "Enter Gene Name:", value = "TP53"),
          checkboxInput("g_network_mutated_interactors", "Include Only Mutated Interactors", value = TRUE),
          checkboxInput("cross", "Show all the interactions", value = FALSE),
          br(),
          h4("Downloads"), 
          p("Here is available the network plot and the complete table of interactions for your interest gene.", style='font-size: 13px;'),
          br(),
          downloadButton("downloadGeneNetwork", "Download Network Plot Image (PDF)"),
          actionButton("downloadGeN", "Download Gene Interactors"),
          br(),br(),
          p("For further analysis is also available the WHOLE dataset of interactions for all the genes that match your paramters selection.", style='font-size: 13px;'), # Add the formal text
          br(),
          actionButton("downloadData", "Download WHOLE Interactome Tables"),
        )
    )
  )
}
