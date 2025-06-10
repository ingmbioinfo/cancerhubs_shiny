library(testthat)

# Mock network_data function similar to the reactive in app.R
network_data <- function(data, interactors){
  tumor_data <- data[["tumor"]][["dataset"]]
  top_genes <- head(tumor_data[order(-tumor_data$network_score), ], 5)

  nodes <- data.frame(
    name = top_genes$gene_list,
    score = top_genes$network_score,
    precog_metaZ = top_genes$precog_metaZ,
    mutation = top_genes$mutation,
    stringsAsFactors = FALSE
  )

  edges <- list()
  for (gene in nodes$name) {
    if (gene %in% names(interactors$gene_interactors)) {
      interactors_list <- interactors$gene_interactors[[gene]]
      interactors_list <- interactors_list[interactors_list %in% nodes$name]
      for (interactor in interactors_list) {
        if (gene != interactor) {
          edges <- append(edges, list(c(gene, interactor)))
        }
      }
    }
  }
  edges_df <- if (length(edges) > 0) do.call(rbind, edges) else NULL

  if (is.null(edges_df)) {
    return(NULL)
  }
  edges_df <- as.data.frame(edges_df, stringsAsFactors = FALSE)
  colnames(edges_df) <- c("from", "to")
  list(nodes = nodes, edges = edges_df)
}

test_that("network_data returns NULL when there are no edges", {
  mock_data <- list(
    tumor = list(dataset = data.frame(
      gene_list = c("A", "B"),
      network_score = c(1, 2),
      precog_metaZ = c(0, 0),
      mutation = c("None", "None")
    ))
  )
  mock_interactors <- list(gene_interactors = list())
  expect_null(network_data(mock_data, mock_interactors))
})
