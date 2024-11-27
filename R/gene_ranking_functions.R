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
