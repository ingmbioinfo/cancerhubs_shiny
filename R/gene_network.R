create_network <- function(data, original, cancer_type, int_type, gene, include_mutated = TRUE, crosses = FALSE,
                           biogrid = biogrid,
                           exp_systems = NULL ) {
  
  print(paste("Include Mutated:", include_mutated))
  
  # Extract the relevant cancer data
  cancer_data <- data[[cancer_type]]
  
  if (is.null(cancer_data)) {
    stop("Invalid cancer type")
  }
  
  if (int_type %in% c("All Genes", "Only MUTATED (Not Precog)")) {
    
    sel_data <- cancer_data[["inter"]]
    selection <- ifelse(include_mutated, "mutated_interactors", "total_interactors")
    
    print(paste("Selected Column:", selection))
    
    if (int_type == "Only MUTATED (Not Precog)") {
      tumor_data <- original[[cancer_type]][["Non_PRECOG"]]
    } else {
      tumor_data <- original[[cancer_type]][["All_Genes"]]
    }
    
    if (int_type == "Only MUTATED (Not Precog)"){
      print("only_mut active")
      sel_data <- sel_data[sel_data$gene_list %in% tumor_data$gene_list, ]
    }
    
    interactors_gene <- sel_data[sel_data$gene_list == gene, selection]
    
    if (!(selection %in% names(sel_data))) {
      stop("Selected column does not exist in the dataset")
    }
    
    if (length(interactors_gene) == 0) {
      validate(need(FALSE, paste(gene, "is not present in this dataset!\n Please check the spelling or select a different tumour/dataset type.")))
    }
    
    interactors <- unlist(interactors_gene)
    
    if (length(interactors) == 0) {
      validate(need(FALSE, paste(gene, "has no interactors in this dataset.\n Please select a different tumour or dataset type.")))
    }
    
    complete_data <- tumor_data[tumor_data$gene_list %in% interactors, ]
    
    missing_interactors <- setdiff(interactors, tumor_data$gene_list)
    
    if (length(missing_interactors) > 0) {
      placeholder_data <- data.frame(
        gene_list  = missing_interactors,
        network_score = 0
      )
      placeholder_data[setdiff(names(tumor_data), names(placeholder_data))] <- NA
      filtered_data <- tumor_data[tumor_data$gene_list %in% interactors, ]
      complete_data <- rbind(filtered_data, placeholder_data)
    }
    
    sorted_data <- complete_data[order(-complete_data$network_score), ]
    top_50 <- head(sorted_data, 50)
    interactors <- top_50$gene_list
  } 
  
  if (int_type %in% c("PRECOG (Mutated or Not)", "Only PRECOG (Not Mutated)")) {
    
    sel_data <- cancer_data[["precog_inter"]]
    selection <- ifelse(include_mutated, "precog_mut", "precog")
    
    print(paste("Selected Column:", selection))
    
    if (int_type == "Only PRECOG (Not Mutated)") {
      tumor_data <- original[[cancer_type]][["Only_PRECOG"]]
    } else {
      tumor_data <- original[[cancer_type]][["PRECOG"]]
    }
    
    if (int_type == "Only PRECOG (Not Mutated)") {
      print("only_precog active")
      sel_data <- sel_data[sel_data$genes %in% tumor_data$gene_list, ]
    }
    
    interactors_gene <- sel_data[sel_data$genes == gene, selection]
    
    if (!(selection %in% names(sel_data))) {
      stop("Selected column does not exist in the dataset")
    }
    
    if (length(interactors_gene) == 0) {
      validate(need(FALSE, paste(gene, "is not present in this dataset!\n Please select a different dataset or tumour.")))
    }
    
    interactors <- unlist(interactors_gene)
    print(length(interactors))
    
    if (length(interactors) == 0) {
      validate(need(FALSE, paste(gene, "has no interactors in this dataset.\n Please select a different gene or dataset.")))
    }
    
    complete_data <- tumor_data[tumor_data$gene_list %in% interactors, ]
    
    missing_interactors <- setdiff(interactors, tumor_data$gene_list)
    
    if (length(missing_interactors) > 0) {
      placeholder_data <- data.frame(
        gene_list = missing_interactors,
        network_score = 0
      )
      placeholder_data[setdiff(names(tumor_data), names(placeholder_data))] <- NA
      filtered_data <- tumor_data[tumor_data$gene_list %in% interactors, ]
      complete_data <- rbind(filtered_data, placeholder_data)
    }
    
    sorted_data <- complete_data[order(-complete_data$network_score), ]
    top_50 <- head(sorted_data, 50)
    interactors <- top_50$gene_list
  }
  
  # Create network edges
  edges <- data.frame(
    from = gene,
    to = interactors
  )
  
  # Remove self-loops early
  edges <- edges[edges$from != edges$to, ]
  
  if (crosses) {
    print("Cross-interaction logic active")    
    
    additional_edges <- data.frame(from = character(), to = character(), stringsAsFactors = FALSE)
    
    for (i in seq_along(interactors)) {
      interactor_i <- interactors[i]
      
      column_name <- ifelse("gene_list" %in% colnames(sel_data), "gene_list", "genes")
      
      interactor_data <- sel_data[sel_data[[column_name]] == interactor_i, selection]
      
      if (length(interactor_data) > 0) {
        interactor_neighbors <- unlist(interactor_data)
        shared_interactors <- intersect(interactor_neighbors, interactors)
        
        if (length(shared_interactors) > 0) {
          new_edges <- data.frame(from = pmin(interactor_i, shared_interactors), 
                                  to = pmax(interactor_i, shared_interactors))
          additional_edges <- rbind(additional_edges, new_edges)
        }
      }
    }
    
    additional_edges <- unique(additional_edges)
    edges <- unique(rbind(edges, additional_edges))
    
    print(paste("Edges before dedup:", nrow(edges)))
    
    edges <- data.frame(
      from = pmin(edges$from, edges$to),
      to   = pmax(edges$from, edges$to)
    )
    
    edges <- unique(edges)
    
    # Remove self-loops again after cross-interaction (belt and braces)
    edges <- edges[edges$from != edges$to, ]
    
    print(paste("Edges after dedup:", nrow(edges)))
  }
  
  # -------------------------------
  # BioGRID experimental filtering
  # -------------------------------
  if (!is.null(biogrid) &&
      !is.null(exp_systems) &&
      !"All" %in% exp_systems) {
    
    bg_sub <- biogrid[biogrid$Experimental.System %in% exp_systems, ]
    
    allowed_pairs <- paste(
      pmin(bg_sub$Official.Symbol.Interactor.A,
           bg_sub$Official.Symbol.Interactor.B),
      pmax(bg_sub$Official.Symbol.Interactor.A,
           bg_sub$Official.Symbol.Interactor.B),
      sep = "__"
    )
    
    edge_pairs <- paste(
      pmin(edges$from, edges$to),
      pmax(edges$from, edges$to),
      sep = "__"
    )
    
    # Separate hub edges from cross edges
    central_edges <- edges$from == gene | edges$to == gene
    hub_edges <- edges[central_edges, , drop = FALSE]
    cross_edges <- edges[!central_edges, , drop = FALSE]
    
    # Filter hub edges through BioGRID
    hub_edge_pairs <- edge_pairs[central_edges]
    hub_edges <- hub_edges[hub_edge_pairs %in% allowed_pairs, , drop = FALSE]
    
    # Filter cross edges through BioGRID
    cross_edge_pairs <- edge_pairs[!central_edges]
    cross_edges <- cross_edges[cross_edge_pairs %in% allowed_pairs, , drop = FALSE]
    
    # Only keep cross edges where BOTH nodes are still connected to the central gene
    valid_interactors <- unique(c(hub_edges$from, hub_edges$to))
    valid_interactors <- valid_interactors[valid_interactors != gene]
    cross_edges <- cross_edges[
      cross_edges$from %in% valid_interactors & 
        cross_edges$to %in% valid_interactors, , drop = FALSE]
    
    edges <- rbind(hub_edges, cross_edges)
  }
  
  if (length(exp_systems) == 0) exp_systems <- "All"
  
  # Create graph object
  g <- graph_from_data_frame(edges, directed = FALSE)
  
  # Use the actual graph node names for color assignment
  graph_nodes <- V(g)$name
  vertex_colors <- rep("#83C9C8", length(graph_nodes))
  
  # Named vector of network scores for fast lookup
  network_score_map <- setNames(top_50$network_score, top_50$gene_list)
  
  # Assign colors based on network scores
  for (i in seq_along(graph_nodes)) {
    node_name <- graph_nodes[i]
    if (node_name == gene) next
    if (node_name %in% names(network_score_map)) {
      vertex_colors[i] <- if (network_score_map[node_name] == 0) "#C9E8E7" else "#83C9C8"
    }
  }
  
  # Assign pink to the central gene
  vertex_colors[graph_nodes == gene] <- "pink"
  
  V(g)$color <- vertex_colors
  
  # Plot the graph
  set.seed(42)
  layout <- layout_with_kk(g)
  
  plot(g, layout = layout,
       vertex.size = 10, vertex.label.cex = 1, 
       vertex.color = vertex_colors,
       vertex.frame.color = vertex_colors,
       vertex.label.color = "black", vertex.label.font = 2, 
       main = "")
  
  title(main = paste("Top50 Interactors of", gene),
        col.main = "black",
        font.main = 1,
        cex.main = 1.4)
  
  g$layout <- layout
  
  return(g)
}