extract_top_n_lines <- function(data, n) {
  extracted_data <- lapply(names(data), function(cancer_type) {
    lapply(names(data[[cancer_type]]), function(subset) {
      df <- data[[cancer_type]][[subset]]
      
      if (!is.data.frame(df)) {
        stop(sprintf("Expected a dataframe at %s - %s, but got something else of class %s.", cancer_type, subset, class(df)))
      }
      
      # Add cancer_type and subset as metadata
      df <- head(df, n) %>%
        mutate(cancer_type = cancer_type, subset = subset)
      
      return(df)
    }) %>% bind_rows()  # Bind all subsets within a cancer type
  }) %>% bind_rows()  # Bind all cancer types
  
  return(extracted_data)
}


get_common_genes_across_cancers <- function(extracted_data, num_cancers) {
  # Initialize an empty list to store results
  category_genes <- list()
  
  # Loop over each unique subset in the extracted data
  for (subset in unique(extracted_data$subset)) {
    # Filter data for the current subset
    subset_data <- extracted_data[extracted_data$subset == subset, ]
    
    # Extract genes across all cancer types
    gene_list <- subset_data$gene_list
    
    # Count the occurrence of each gene across all cancers
    gene_count <- table(gene_list)
    
    # Filter for genes that appear in at least 'num_cancers' cancers
    common_genes <- names(gene_count[gene_count >= num_cancers])
    
    # Skip if no genes meet the criteria
    if (length(common_genes) == 0) {
      category_genes[[subset]] <- data.frame(Gene = character(0), Cancers = character(0))
      next
    }
    
    # For each common gene, find out in which cancers it appears
    gene_cancer_list <- sapply(common_genes, function(gene) {
      present_in_cancers <- unique(subset_data$cancer_type[subset_data$gene_list == gene])
      paste(present_in_cancers, collapse = ", ")
    })
    
    # Inside get_common_genes_across_cancers
    sorted_df <- data.frame(
      Gene = common_genes,
      TumorCount = sapply(common_genes, function(gene) sum(subset_data$gene_list == gene)),
      Cancers = gene_cancer_list,
      stringsAsFactors = FALSE
    )
    
    # Sort by TumorCount descending
    sorted_df <- sorted_df[order(-sorted_df$TumorCount), ]
    category_genes[[subset]] <- sorted_df
    
    
  }
  
  # Return the list of common genes for each subset
  return(category_genes)
}
