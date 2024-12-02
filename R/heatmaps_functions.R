
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

# Function to create heatmaps for each category
create_category_heatmaps <- function(gene_presence_df, top_n = 50) {
  heatmaps <- list()
  
  for (category in unique(gene_presence_df$Category)) {
    category_data <- gene_presence_df %>% filter(Category == category)
    
    # Select top N genes based on presence across cancer types
    category_data <- category_data %>%
      mutate(TotalPresence = rowSums(across(-c(Gene, Category)))) %>%
      arrange(desc(TotalPresence)) %>%   # Sort by TotalPresence (most present first)
      head(top_n)
    
    # Order genes by TotalPresence, then alphabetically
    category_data <- category_data %>%
      arrange((TotalPresence), Gene)  # Sorting by TotalPresence first, then by Gene name
    
    # Reshape data to long format
    long_data <- category_data %>%
      pivot_longer(cols = -c(Gene, Category, TotalPresence), names_to = "CancerType", values_to = "Presence")
    
    # Convert 'Presence' to a factor with levels "Present" and "Not Present"
    long_data$Presence <- factor(long_data$Presence, levels = c(0, 1), labels = c("Not Present", "Present"))
    
    # Ensure genes are ordered by TotalPresence in the heatmap
    long_data$Gene <- factor(long_data$Gene, levels = category_data$Gene)
    
    # Create the heatmap
    heatmap <- ggplot(long_data, aes(x = CancerType, y = Gene, fill = Presence)) +
      geom_tile(color = "white") +
      scale_fill_manual(values = c("Not Present" = "pink", "Present" = "#0A9396")) +
      labs(title = paste("Gene Presence in", category),
           x = "Cancer Type",
           y = "Gene",
           fill = "Presence") +  # Ensure the fill is labeled as "Presence"
      theme_minimal() +
      theme(axis.text.y = element_text(size = 6),
            axis.text.x = element_text(angle = 45, hjust = 1),
            legend.position = "bottom")  # Adjust legend position if needed
    
    heatmaps[[category]] <- heatmap
  }
  
  return(heatmaps)
}


# Display the heatmaps
#for (category in names(heatmaps)) {
#  print(heatmaps[[category]])
#}


