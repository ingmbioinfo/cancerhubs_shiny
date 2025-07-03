plot_tumor_network <- function(data, interactors, tumor, dataset_type = "All_Genes", top_n = 10, mutated_interactors = TRUE, color_by = "network_score") {
  if (!tumor %in% names(data)) stop("Selected tumor is not available in the data")
  if (!dataset_type %in% names(data[[tumor]])) stop("Selected dataset type is not available for the tumor")
  
  tumor_data <- data[[tumor]][[dataset_type]]
  top_genes <- head(tumor_data[order(-tumor_data$network_score), ], top_n)
  top_gene_list <- top_genes$gene_list
  
  nodes <- c()
  edges <- list()
  
  for (i in seq_len(nrow(top_genes))) {
    gene <- top_genes$gene_list[i]
    nodes <- c(nodes, gene)
    
    if (gene %in% names(interactors$gene_interactors)) {
      gene_interactors <- interactors$gene_interactors[[gene]]
      gene_interactors <- gene_interactors[gene_interactors %in% top_gene_list]
      
      if (mutated_interactors) {
        mutated_indices <- top_genes$mutation[match(gene_interactors, top_genes$gene_list)] %in% c("ORF", "NON_ORF", "BOTH")
        gene_interactors <- gene_interactors[mutated_indices]
      }
      
      for (interactor in gene_interactors) {
        if (gene != interactor) {
          nodes <- unique(c(nodes, interactor))
          edges <- append(edges, list(c(gene, interactor)))
        }
      }
    }
  }
  
  if (length(edges) == 0) {
    validate(need(FALSE, "The selected top genes for this tumor do not interact with each other.\n Please select more genes or change the dataset"))
  }
  
  edges_matrix <- do.call(rbind, edges)
  g <- graph_from_edgelist(edges_matrix, directed = FALSE)
  V(g)$label <- V(g)$name
  
  if (color_by == "network_score") {
    scores <- top_genes$network_score[match(V(g)$name, top_genes$gene_list)]
    scores[is.na(scores)] <- max(scores, na.rm = TRUE) + 1
    colors <- colorRampPalette(brewer.pal(9, "YlOrRd"))(100)
    score_colors <- colors[findInterval(scores, seq(min(scores), max(scores), length.out = 100))]
    V(g)$color <- score_colors
  } else if (color_by == "precog_metaZ") {
    metaz_values <- top_genes$precog_metaZ[match(V(g)$name, top_genes$gene_list)]
    metaz_values[is.na(metaz_values)] <- 0
    colors <- colorRampPalette(c("blue", "white", "red"))(100)
    metaz_colors <- colors[findInterval(metaz_values, seq(min(metaz_values), max(metaz_values), length.out = 100))]
    V(g)$color <- metaz_colors
  }
  
  precog_status <- ifelse(V(g)$name %in% top_genes$gene_list[top_genes$precog_metaZ >= 1.96 | top_genes$precog_metaZ <= -1.96], "PRECOG", "Non-PRECOG")
  mutation_status <- top_genes$mutation[match(V(g)$name, top_genes$gene_list)]
  mutation_status[is.na(mutation_status)] <- "None"
  V(g)$shape <- ifelse(precog_status == "PRECOG", "circle", "square")
  V(g)$size <- ifelse(mutation_status %in% c("ORF", "NON_ORF", "BOTH"), 30, 15)
  
  layout <- layout_with_fr(g, dim = 3)
  layout <- as.data.frame(layout)
  rownames(layout) <- V(g)$name
  colnames(layout) <- c("x", "y", "z")
  
  plot_data <- data.frame(
    x = layout$x,
    y = layout$y,
    z = layout$z,
    text = V(g)$label,
    color = V(g)$color,
    size = V(g)$size,
    shape = V(g)$shape
  )
  
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
      line = list(width = 0.2, color = "gray", opacity = 0.3),
      hoverinfo = "none",
      showlegend = FALSE
    )
  }
  
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
        x = 1.3,
        y = 0.7
      ),
      symbol = ifelse(plot_data$shape == "circle", "circle", "square"),
      line = list(width = 0.5, color = "black")
    ),
    hoverinfo = "text",
    showlegend = FALSE
  )
  
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
  
  # Dummy traces for shape and size legends
  # Dummy traces for legend (simulated using size and color, not shape)
  fig <- fig %>%
    add_trace(
      type = "scatter3d", mode = "markers", x = 0, y = 0, z = 0, opacity = 0,
      marker = list(shape = "circle", size = 0, color = "gray"),
      name = "◯ Mutated (large)", showlegend = TRUE
    ) %>%
    add_trace(
      type = "scatter3d", mode = "markers", x = 0, y = 0, z = 0, opacity = 0,
      marker = list(symbol = "circle", size = 0, color = "gray"),
      name = "○ Non-mutated (small)", showlegend = TRUE
    ) %>%
    add_trace(
      type = "scatter3d", mode = "markers", x = 0, y = 0, z = 0, opacity = 0,
      marker = list(symbol = "circle", size = 0, color = "gray"),
      name = "● PRECOG (circle)", showlegend = TRUE
    ) %>%
    add_trace(
      type = "scatter3d", mode = "markers", x = 0, y = 0, z = 0, opacity = 0,
      marker = list(symbol = "square", size = 0, color = "gray"),
      name = "■ Non-PRECOG (square)", showlegend = TRUE
    )
  
  
  fig <- fig %>% layout(
    title = paste("Network for", tumor, "-", dataset_type),
    scene = list(
      xaxis = list(title = "", showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
      yaxis = list(title = "", showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
      zaxis = list(title = "", showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE)
    ),
    showlegend = TRUE,
    legend = list(
      x = 1.15,
      y = 0.35,
      bgcolor = "rgba(255,255,255,0.8)",
      font = list(size = 14, color = "black"),
      itemclick = FALSE,
      itemdoubleclick = FALSE
    ),
    margin = list(r = 150)
  )
  
  fig
}
