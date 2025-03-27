# Function to extract the top n genes for each cancer type and category
extract_top_n_genes <- function(data, n) {
  extracted_data <- lapply(names(data), function(cancer_type) {
    lapply(names(data[[cancer_type]]), function(category) {
      df <- data[[cancer_type]][[category]]
      
      if (!is.data.frame(df)) {
        stop(sprintf("Expected a dataframe at %s - %s, but got something else of class %s.", cancer_type, category, class(df)))
      }
      
      if (!"gene_list" %in% colnames(df)) {
        stop(sprintf("Column 'gene_list' not found in dataframe at %s - %s.", cancer_type, category))
      }
      
      # Extract top n genes
      top_n_df <- head(df, n)
      return(top_n_df$gene_list)
    })
  })
  
  # Name the extracted data structure
  names(extracted_data) <- names(data)
  for (i in seq_along(extracted_data)) {
    names(extracted_data[[i]]) <- names(data[[i]])
  }
  
  return(extracted_data)
}

# Function to create a gene presence matrix per category
create_presence_matrix_per_category <- function(extracted_data) {
  # Initialize an empty list to store presence matrices for each category
  presence_data <- list()
  
  # For each category, create a presence matrix
  for (category in unique(unlist(lapply(extracted_data, names)))) {
    # Get the list of genes for this category across all cancer types
    all_genes_in_category <- unique(unlist(lapply(extracted_data, function(x) {
      if (category %in% names(x)) {
        return(x[[category]])
      }
    })))
    
    # Initialize a presence matrix for this category
    presence_matrix <- matrix(0, nrow = length(all_genes_in_category), ncol = length(extracted_data),
                              dimnames = list(all_genes_in_category, names(extracted_data)))
    
    # Populate the matrix based on whether the gene is present in the cancer type
    for (cancer_type in names(extracted_data)) {
      if (!category %in% names(extracted_data[[cancer_type]])) next
      genes_in_category <- extracted_data[[cancer_type]][[category]]
      presence_matrix[all_genes_in_category %in% genes_in_category, cancer_type] <- 1
    }
    
    # Convert matrix to a dataframe and add it to the list
    presence_df <- as.data.frame(presence_matrix)
    presence_df$Gene <- rownames(presence_df)
    presence_df$Category <- category
    
    presence_data[[category]] <- presence_df
  }
  
  # Combine presence data for all categories into a single dataframe
  combined_presence_df <- bind_rows(presence_data)
  return(combined_presence_df)
}


create_category_heatmaps <- function(gene_presence_df, top_n = 50, num_cancers = 1) {
  heatmaps <- list()
  
  print(unique(gene_presence_df$Category))
  for (category in unique(gene_presence_df$Category)) {
    category_data <- gene_presence_df %>% filter(Category == category)
    
    # Calculate TotalPresence before filtering
    category_data <- category_data %>%
      mutate(TotalPresence = rowSums(across(-c(Gene, Category))))
    
    # Filter genes expressed in at least num_cancers and sort consistently
    filtered_data <- category_data %>%
      filter(TotalPresence >= num_cancers) %>%
      arrange(desc(TotalPresence), Gene) # Sort by TotalPresence, then alphabetically
    
    nrow(filtered_data)
    print(filtered_data)
    
    # Limit to top N genes after filtering
    top_n_data <- head(filtered_data, top_n)
    top_n_data = top_n_data %>% arrange(TotalPresence, desc(Gene))
    
    # Reshape data to long format
    long_data <- top_n_data %>%
      pivot_longer(cols = -c(Gene, Category, TotalPresence), names_to = "CancerType", values_to = "Presence")
    
    # Convert 'Presence' to numeric for Plotly
    long_data$Presence <- as.numeric(long_data$Presence)
    
    # Ensure genes are ordered by TotalPresence in the heatmap
    long_data$Gene <- factor(long_data$Gene, levels = top_n_data$Gene)
    
    print("longdata_gene")
    print(length(long_data$Gene))
    
    if(length(long_data$Gene) == 0)  next
    
    # Create the heatmap using Plotly
    heatmap <- plot_ly(
      data = long_data,
      x = ~CancerType,
      y = ~Gene,
      z = ~Presence,
      type = 'heatmap',
      colors = c('pink', '#0A9396'),
      text = ~paste("Gene:", Gene, "<br>Presence:", ifelse(Presence == 1, "Present", "Not Present")),
      hoverinfo = 'text',
      showscale = FALSE
    ) %>%
      layout(
        title = paste("Gene Presence in", category),
        xaxis = list(title = "Cancer Type", tickangle = 45),
        yaxis = list(title = "Gene", tickfont = list(size = 6)),
        margin = list(t = 50)
      )
    
    grid_lines <- list()
    
    # Add horizontal grid lines, offset by 0.5
    for (i in seq_along(unique(long_data$Gene))) {
      grid_lines <- append(grid_lines, list(
        list(type = "line",
             xref = "paper", yref = "y",
             x0 = 0, x1 = 1, y0 = i - 0.5, y1 = i - 0.5,
             line = list(color = "white", width = 1))
      ))
    }
    
    # Add vertical grid lines, offset by 0.5
    for (i in seq_along(unique(long_data$CancerType))) {
      grid_lines <- append(grid_lines, list(
        list(type = "line",
             xref = "x", yref = "paper",
             x0 = i - 0.5, x1 = i - 0.5, y0 = 0, y1 = 1,
             line = list(color = "white", width = 1))
      ))
    }
    
    
    heatmap <- heatmap %>%
      layout(shapes = grid_lines)
    
    
    heatmaps[[category]] <- heatmap
  }
  
  return(heatmaps)
}



