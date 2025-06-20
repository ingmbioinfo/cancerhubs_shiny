
create_network <- function(data, original, cancer_type, int_type, gene, include_mutated = TRUE, crosses = FALSE ) {
  
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
      
      sel_data =sel_data[sel_data$gene_list %in% tumor_data$gene_list,]
    }
    
    
    interactors_gene <- sel_data[sel_data$gene_list == gene, selection]
    
    if (!(selection %in% names(sel_data))) {
      stop("Selected column does not exist in the dataset")
    }
    
    if (length(interactors_gene) == 0) {
      validate(need(FALSE,paste(gene, "is not present in this dataset!\n Please check the spelling or select a different tumour/dataset type.")))
    }
    
    # Extract interactors
    interactors <- unlist(interactors_gene)
    
    if (length(interactors) == 0) {
      validate(need(FALSE,paste(gene, "has no interactors in this dataset.\n Please select a different tumour or dataset type.")))
    }
  
  
    
    complete_data <- tumor_data[tumor_data$gene_list %in% interactors, ]
    
    # Create a dataframe for missing interactors
    missing_interactors <- setdiff(interactors, tumor_data$gene_list)
    
    if (length(missing_interactors) > 0) {
      placeholder_data <- data.frame(
        gene_list  = missing_interactors,
        network_score = 0
      )
      
      # Add NA for all other columns dynamically
      placeholder_data[setdiff(names(tumor_data), names(placeholder_data))] <- NA
      
      # Filter tumor data for existing interactors
      filtered_data <- tumor_data[tumor_data$gene_list %in% interactors, ]
      
      # Combine filtered data with placeholder data
      complete_data <- rbind(filtered_data, placeholder_data)
    }
    
    # Sort by network score in descending order
    sorted_data <- complete_data[order(-complete_data$network_score), ]
    
    # Extract the top 50 interactors
    top_50 <- head(sorted_data, 50)
    
    # Match the top 50
    interactors <- top_50$gene_list
    
  } 
  
   if (int_type %in% c("PRECOG (Mutated or Not)", "Only PRECOG (Not Mutated)")){
     
     sel_data <- cancer_data[["precog_inter"]]
     selection <- ifelse(include_mutated, "precog_mut", "precog")
     
     print(paste("Selected Column:", selection))
     
     if (int_type == "Only PRECOG (Not Mutated)") {
       tumor_data <- original[[cancer_type]][["Only_PRECOG"]]
     } else {
       tumor_data <- original[[cancer_type]][["PRECOG"]]
     }
    
     if (int_type == "Only PRECOG (Not Mutated)"){
       print("only_precog active")
       
       sel_data =sel_data[sel_data$genes %in% tumor_data$gene_list,]
     }
    
    interactors_gene <- sel_data[sel_data$genes == gene, selection]
    
    if (!(selection %in% names(sel_data))) {
      stop("Selected column does not exist in the dataset")
    }
    
    if (length(interactors_gene) == 0) {
      validate(need(FALSE,paste(gene, "is not present in this dataset!\n Please select a different dataset or tumour.")))
    }
    
    # Extract interactors
    interactors <- unlist(interactors_gene)
    print(length(interactors))
    
    if (length(interactors) == 0) {
      validate(need(FALSE,paste(gene, "has no interactors in this dataset.\n Please select a different gene or dataset.")))
    }
    
    complete_data <- tumor_data[tumor_data$gene_list %in% interactors, ]
    
    # Create a dataframe for missing interactors
    missing_interactors <- setdiff(interactors, tumor_data$gene_list)
    
    if (length(missing_interactors) > 0) {
      placeholder_data <- data.frame(
        gene_list = missing_interactors,
        network_score = 0
      )
      
      # Add NA for all other columns dynamically
      placeholder_data[setdiff(names(tumor_data), names(placeholder_data))] <- NA
      
      # Filter tumor data for existing interactors
      filtered_data <- tumor_data[tumor_data$gene_list %in% interactors, ]
      complete_data <- rbind(filtered_data, placeholder_data)
    }
    
    # Sort by network score in descending order
    sorted_data <- complete_data[order(-complete_data$network_score), ]
    
    # Extract the top 50 interactors
    top_50 <- head(sorted_data, 50)
    
    # Match the top 50
    interactors <- top_50$gene_list
  }
  
  # Create network edges
  edges <- data.frame(
    from = gene,
    to = interactors
  )
  
  if (crosses) {
    print("Cross-interaction logic active")    
    
    additional_edges <- data.frame(from = character(), to = character(), stringsAsFactors = FALSE)
    
    for (i in seq_along(interactors)) {
      interactor_i <- interactors[i]
      
      column_name <- ifelse("gene_list" %in% colnames(sel_data), "gene_list", "genes")
      
      
      # Get interactors of interactor_i
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
    
    # Remove duplicate edges
    additional_edges <- unique(additional_edges)
    
    # Combine all edges
    edges <- unique(rbind(edges, additional_edges))
    print(paste("Edges before:", nrow(edges)))
    
    # Sort each edge and remove duplicates
    edges <- data.frame(
      from = pmin(edges$from, edges$to),  # Always take the smaller value for 'from'
      to = pmax(edges$from, edges$to)    # Always take the larger value for 'to'
    )
    
    # Remove duplicate edges
    edges <- unique(edges)
    
    print(paste("Edges after:", nrow(edges)))
    
    edges <- edges[edges$from != edges$to, ]
  }
  
  # Create graph object
  g <- graph_from_data_frame(edges, directed = FALSE)
  
  # Initialize default colors
  vertex_colors <- rep("#83C9C8", length(V(g)))  # Default color
  
  # Create a named vector of network scores for fast lookup
  network_score_map <- setNames(top_50$network_score, top_50$gene_list)
  
  # Assign colors based on network scores
  for (i in seq_along(V(g)$name)) {
    node_name <- V(g)$name[i]
    
    if (node_name %in% names(network_score_map)) {
      if (network_score_map[node_name] == 0) {
        vertex_colors[i] <- "#C9E8E7"  # Lighter shade for zero score
      } else {
        vertex_colors[i] <- "#83C9C8"  # Darker shade for nonzero score
      }
    }
  }
  
  # Assign pink color to the central gene
  vertex_colors[V(g)$name == gene] <- "pink"
  
  V(g)$color <- vertex_colors
  
  # Plot the graph
  plot(g, vertex.size = 10, vertex.label.cex = 1, 
       vertex.color = vertex_colors,
       vertex.frame.color = vertex_colors,
       vertex.label.color = "black", vertex.label.font = 2, 
       main = "")
  
  title(main = paste("Top50 Interactors of", gene),
        col.main = "black",      # Title color
        font.main = 1,          # Font style (1=plain, 2=bold, 3=italic, 4=bold italic)
        cex.main = 1.4)         # Title size (default is 1)
  
  return(g)
}








get_file_link <- function(dataframe, int_type, include_mutated, file_format = "xlsx") {
  int_type_part <- if (int_type == "PRECOG (Mutated or Not)") {
    "precog"
  } else if (int_type == "All Genes") {
    "all_genes"
  } else if (int_type == "Only MUTATED (Not Precog)") {
    "only_mutated"
  } else if (int_type == "Only PRECOG (Not Mutated)") {
    "only_precog"
  }
  
  mutated_part <- if (include_mutated) "_mut" else ""
  
  # Adjust base directory depending on file format
  base_dir <- if (file_format == "xlsx") "EXCEL" else "CSV"
  
  # Fetch pre-zipped CSV folders instead of raw directories
  file_name <- paste0("https://github.com/ingmbioinfo/cancerhubs/raw/main/result/interactions_download/",
                      base_dir, "/", dataframe, "_",
                      int_type_part, mutated_part,
                      if (file_format == "xlsx") ".xlsx" else ".zip")  
  
  return(file_name)
}


