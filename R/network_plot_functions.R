plot_tumor_network <- function(data, interactors, tumor, dataset_type = "All_Genes", top_n = 10, mutated_interactors = TRUE, color_by = "network_score") {
  # Check if the selected tumor exists in the data
  if (!tumor %in% names(data)) {
    stop("Selected tumor is not available in the data")
  }
  
  # Check if the selected dataset type exists in the tumor data
  if (!dataset_type %in% names(data[[tumor]])) {
    stop("Selected dataset type is not available for the tumor")
  }
  
  # Extract data for the selected tumor and dataset type
  tumor_data <- data[[tumor]][[dataset_type]]
  
  # Select the top N genes based on network_score
  top_genes <- head(tumor_data[order(-tumor_data$network_score), ], top_n)
  top_gene_list <- top_genes$gene_list
  
  # Initialize the graph without the central tumor node
  nodes <- c()
  edges <- list()
  
  # Add the top genes as nodes
  for (i in seq_len(nrow(top_genes))) {
    gene <- top_genes$gene_list[i]
    nodes <- c(nodes, gene)
    
    # Find the interactors of the gene that are also among the top selected genes
    if (gene %in% names(interactors$as.matrix.interactors.)) {
      gene_interactors <- interactors$as.matrix.interactors.[[gene]]
      gene_interactors <- gene_interactors[gene_interactors %in% top_gene_list]
      
      if (mutated_interactors) {
        # Filter interactors to include only those that are mutated (ORF, NON_ORF, BOTH)
        mutated_indices <- top_genes$mutation[match(gene_interactors, top_genes$gene_list)] %in% c("ORF", "NON_ORF", "BOTH")
        gene_interactors <- gene_interactors[mutated_indices]
      }
      
      # Add interactors as nodes and edges connecting to the gene
      for (interactor in gene_interactors) {
        if (gene != interactor) {  # Avoid self-loops
          nodes <- unique(c(nodes, interactor))
          edges <- append(edges, list(c(gene, interactor)))
        }
      }
    }
  }
  
  # Create an igraph object from the nodes and edges
  if (length(edges) == 0) {
    stop("No edges available to create a graph")
  }
  edges_matrix <- do.call(rbind, edges)
  g <- graph_from_edgelist(edges_matrix, directed = FALSE)
  V(g)$label <- V(g)$name
  
  # Set color based on the selected attribute
  if (color_by == "network_score") {
    scores <- top_genes$network_score[match(V(g)$name, top_genes$gene_list)]
    scores[is.na(scores)] <- max(scores, na.rm = TRUE) + 1 # Handle interactors not in top genes
    colors <- colorRampPalette(brewer.pal(9, "YlOrRd"))(100)
    score_colors <- colors[findInterval(scores, seq(min(scores), max(scores), length.out = 100))]
    V(g)$color <- score_colors
  } else if (color_by == "precog_metaZ") {
    metaz_values <- top_genes$precog_metaZ[match(V(g)$name, top_genes$gene_list)]
    metaz_values[is.na(metaz_values)] <- 0 # Handle interactors not in top genes
    colors <- colorRampPalette(c("blue", "white", "red"))(100)
    metaz_colors <- colors[findInterval(metaz_values, seq(min(metaz_values), max(metaz_values), length.out = 100))]
    V(g)$color <- metaz_colors
  }
  
  # Add attributes for PRECOG and mutation status to determine shape and size
  precog_status <- ifelse(V(g)$name %in% top_genes$gene_list[top_genes$precog_metaZ >= 1.96 | top_genes$precog_metaZ <= -1.96], "PRECOG", "Non-PRECOG")
  mutation_status <- top_genes$mutation[match(V(g)$name, top_genes$gene_list)]
  mutation_status[is.na(mutation_status)] <- "None"
  
  # Set vertex shape based on PRECOG status
  V(g)$shape <- ifelse(precog_status == "PRECOG", "circle", "square")
  
  # Set vertex size based on mutation status
  V(g)$size <- ifelse(mutation_status %in% c("ORF", "NON_ORF", "BOTH"), 30, 15)
  
  # Convert graph to plotly-friendly format
  layout <- layout_with_fr(g, dim = 3)
  layout <- as.data.frame(layout)
  rownames(layout) <- V(g)$name
  colnames(layout) <- c("x", "y", "z")
  
  # Create data frame for plotly
  plot_data <- data.frame(
    x = layout$x,
    y = layout$y,
    z = layout$z,
    text = V(g)$label,
    color = V(g)$color,
    size = V(g)$size,
    shape = V(g)$shape
  )
  
  # Define edge traces
  edge_traces <- list()
  for (e in 1:ecount(g)) {
    v1 <- ends(g, e)[1]
    v2 <- ends(g, e)[2]
    edge_traces[[e]] <- list(
      type = "scatter3d",
      mode = "lines",
      x = c(layout[v1, "x"], layout[v2, "x"]),
      y = c(layout[v1, "y"], layout[v2, "y"]),
      z = c(layout[v1, "z"], layout[v2, "z"]),
      line = list(width = 1, color = "gray"),
      hoverinfo = "none",
      showlegend = FALSE  # Hide edge traces from legend
    )
  }
  
  # Define node trace
  node_trace <- list(
    type = "scatter3d",
    mode = "markers+text",
    x = plot_data$x,
    y = plot_data$y,
    z = plot_data$z,
    text = plot_data$text,
    textposition = "top center",
    marker = list(
      size = plot_data$size,
      color = plot_data$color,
      colorscale = if (color_by == "network_score") "YlOrRd" else list(c(0, "blue"), c(0.5, "white"), c(1, "red")),
      reversescale = if (color_by == "network_score") TRUE else FALSE,
      cmin = if (color_by == "precog_metaZ") min(metaz_values) else min(scores),
      cmax = if (color_by == "precog_metaZ") max(metaz_values) else max(scores),
      colorbar = list(
        title = if (color_by == "network_score") "Network Score" else "Precog MetaZ",
        thickness = 10,
        len = 0.3,
        x = 1.3  # Move colorbar further to the right
      ),
      symbol = ifelse(plot_data$shape == "circle", "circle", "square"),
      line = list(width = 0.5, color = "black")
    ),
    hoverinfo = "text",
    showlegend = FALSE  # Hide node traces from legend
  )
  
  # Create the plotly figure
  fig <- plot_ly()
  for (edge_trace in edge_traces) {
    fig <- fig %>% add_trace(
      type = edge_trace$type,
      mode = edge_trace$mode,
      x = edge_trace$x,
      y = edge_trace$y,
      z = edge_trace$z,
      line = edge_trace$line,
      hoverinfo = edge_trace$hoverinfo,
      showlegend = edge_trace$showlegend
    )
  }
  fig <- fig %>% add_trace(
    type = node_trace$type,
    mode = node_trace$mode,
    x = node_trace$x,
    y = node_trace$y,
    z = node_trace$z,
    text = node_trace$text,
    textposition = node_trace$textposition,
    marker = node_trace$marker,
    hoverinfo = node_trace$hoverinfo,
    showlegend = node_trace$showlegend
  )
  
  # Add annotations for shape and size legends (higher, closer to colorbar)
  fig <- fig %>% layout(
    title = paste("Network for", tumor, "-", dataset_type),
    scene = list(
      xaxis = list(title = "", showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
      yaxis = list(title = "", showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
      zaxis = list(title = "", showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE)
    ),
    showlegend = TRUE,
    margin = list(r = 250, b = 150),  # Add more space to the right and bottom
    annotations = list(
      list(
        x = 1.35, y = 0.25, text = "Shape Legend:\nCircle: PRECOG\nSquare: Non-PRECOG",
        showarrow = FALSE, xref = "paper", yref = "paper", align = "right", font = list(size = 9)
      ),
      list(
        x = 1.35, y = 0.10, text = "Size Legend:\nLarge: Mutated (ORF/NON_ORF/BOTH)\nSmall: Non-mutated",
        showarrow = FALSE, xref = "paper", yref = "paper", align = "right", font = list(size = 9)
      )
    )
  )
  
  # Render the interactive 3D plot
  fig
}
