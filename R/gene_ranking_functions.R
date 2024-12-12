get_gene_ranking <- function(gene_name, subset_df, data) {
  req(gene_name, subset_df)
  
  # Initialize an empty dataframe to store rankings
  rankings <- data.frame(
    Tumor = character(),
    Rank = numeric(),
    TotalGenes = numeric(),
    PrecogMetaZ = numeric(),
    MutationStatus = character(),
    stringsAsFactors = FALSE
  )
  
  # Iterate through each cancer type
  for (cancer_type in names(data)) {
    df <- data[[cancer_type]][[subset_df]]
    
    # Check if the gene exists in the dataframe
    if (gene_name %in% df$gene_list) {
      df <- df[order(-df$network_score, na.last = TRUE), ]
      rank <- which(df$gene_list == gene_name)
      precog_metaZ <- df$precog_metaZ[rank]
      mutation_status <- df$mutation[rank]
      total_genes <- nrow(df)
      
      rankings <- rbind(rankings, data.frame(
        Tumor = cancer_type,
        Rank = rank,
        TotalGenes = total_genes,
        PrecogMetaZ = precog_metaZ,
        MutationStatus = mutation_status
      ))
    }
  }
  # Order rankings by rank for y-axis reordering
  rankings <- rankings[order(rankings$Rank), ]
  rankings
}

pan_cancer_ranking <- function(data, df = 'All_Genes') {
  l <- list()
  for (i in names(data)) {
    t_data <- data[[i]][[df]]
    tot <- dim(t_data)[1]
    t_data$c_score <- 1 - (1:nrow(t_data)) / tot
    l[[i]] <- t_data[, c(1, 7)]  # Select gene_list and c_score
  }
  merged_df <- reduce(l, full_join, by = "gene_list")
  merged_df$score <- rowSums(merged_df[, -1], na.rm = TRUE)
  merged_df <- merged_df[order(merged_df$score, decreasing = TRUE), c('gene_list', 'score')]
  merged_df$score <- 100 * merged_df$score / max(merged_df$score)
  rownames(merged_df) <- 1:nrow(merged_df)
  return(merged_df)
}
