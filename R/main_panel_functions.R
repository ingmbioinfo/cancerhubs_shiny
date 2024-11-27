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
