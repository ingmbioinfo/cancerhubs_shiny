Get_gene_interactors <- function(data, original, cancer_type, int_type, gene, include_mutated = TRUE) {
  
  cancer_data <- data[[cancer_type]]
  if (is.null(cancer_data)) stop("Invalid cancer type")
  
  # Select the correct interaction column
  int_col <- if (int_type %in% c("All Genes", "Only MUTATED (Not Precog)")) {
     if (include_mutated) "mutated_interactors" else "total_interactors"
  } else {
    if (include_mutated) "precog_mut" else "precog"
  }
  
  # Select the correct dataset
  sel_data <- if (int_type %in% c("All Genes", "Only MUTATED (Not Precog)")) cancer_data[["inter"]] else cancer_data[["precog_inter"]]
  tumor_data <- original[[cancer_type]][[if (int_type =="All Genes") "All_Genes" else if (int_type == "Only MUTATED (Not Precog)") "Non_PRECOG" else if (int_type == "Only PRECOG (Not Mutated)")"Only_PRECOG" else "PRECOG"]]
  
  column_name <- if ("gene_list" %in% colnames(sel_data)) "gene_list" else "genes"
  
  if (int_type %in% c("Only MUTATED (Not Precog)", "Only PRECOG (Not Mutated)")) {
    sel_data <- sel_data[sel_data[[column_name]] %in% tumor_data$gene_list, ]
  }
  
  
  # Get direct interactors of the input gene
  if (!(int_col %in% names(sel_data))) stop("Column missing in data")
  
  interactors_gene <- sel_data[sel_data[[column_name]] == gene, int_col]
  
  if (length(interactors_gene) == 0) {
    validate(need(FALSE,paste(gene, "is not present in this dataset!")))
  }
  
  interactors <- unlist(interactors_gene)  # Direct interactors only
  
  if (length(interactors) == 0) {
    validate(need(FALSE,paste(gene, "has no interactors in this dataset!")))
  }
  
  # All nodes in the network
  all_genes <- unique(c(gene, interactors))
  
  # Create Nodes Dataframe
  nodes <- tumor_data[tumor_data$gene_list %in% all_genes, ]
  
  # Add missing genes as placeholders
  missing_genes <- setdiff(all_genes, nodes$gene_list)
  if (length(missing_genes) > 0) {
    missing_nodes <- as.data.frame(matrix(NA, nrow = length(missing_genes), ncol = ncol(nodes)))
    colnames(missing_nodes) <- colnames(nodes)
    missing_nodes$gene_list <- missing_genes
    nodes <- rbind(nodes, missing_nodes)
  }
  
  # Create edges between input gene and its interactors
  edges <- data.frame(from = gene, to = interactors)
  
  # Create edges among interactors themselves
  additional_edges <- do.call(rbind, lapply(interactors, function(interactor_i) {
    interactor_data <- sel_data[sel_data[[column_name]] == interactor_i, int_col]
    if (length(interactor_data) > 0) {
      shared_interactors <- intersect(unlist(interactor_data), interactors)  # Only check within interactors
      if (length(shared_interactors) > 0) {
        return(data.frame(from = interactor_i, to = shared_interactors))
      }
    }
    return(NULL)
  }))
  
  # Combine edges
  edges <- unique(rbind(edges, additional_edges))
  edges <- edges[edges$from != edges$to, ]  # Remove self-edges
  edges <- unique(data.frame(from = pmin(edges$from, edges$to), to = pmax(edges$from, edges$to)))  # Remove duplicates
  
  return(list(EDGES = edges, NODES = nodes))
}
