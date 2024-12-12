create_ranking_plot <- function(rankings, gene, dataframe_subset) {
  if (nrow(rankings) == 0) {
    plot(1, type = "n", xlab = "", ylab = "", main = "Gene not found in any tumor type")
  } else {
    # Add a column with rank/total genes information
    rankings$RankOutOf <- paste0(rankings$Rank, " / ", rankings$TotalGenes)
    # Create the plot
    ggplot(rankings, aes(x = -Rank, y = reorder(Tumor, -Rank), color = Tumor)) +
      geom_point(size = 7, shape = 16) +
      geom_text(aes(label = RankOutOf), hjust = -0.3, vjust = -0.5, size = 6, show.legend = FALSE) +
      scale_x_reverse(expand = expansion(mult = c(0.05, 0.4))) +
      labs(
        title = paste("Ranking of", gene, "in", gsub("_", " ", dataframe_subset)),
        x = "Rank (1 = Top Importance)",
        y = "Tumor Type",
        color = "Tumor Type"
      ) +
      theme_classic() +
      theme(
        axis.text.y = element_text(size = 12),
        axis.text.x = element_blank(),
        plot.title = element_text(hjust = 0.5, size = 14),
        panel.grid.major = element_line(color = "#dfe6ec"),
        legend.position = "bottom",
        plot.margin = margin(10, 40, 10, 10)
      ) +
      guides(color = guide_legend(override.aes = list(size = 5, shape = 16)))
  }
}

create_pan_cancer_position_plot <- function(pan_cancer_results, gene) {
  # Check if the gene exists in the pan-cancer rankings
  if (!gene %in% pan_cancer_results$gene_list) {
    plot(1, type = "n", xlab = "", ylab = "", main = "Gene not found in Pan-Cancer ranking")
  } else {
    # Get the score of the gene
    gene_score <- pan_cancer_results$score[pan_cancer_results$gene_list == gene]
    
    # Create the plot
    ggplot() +
      # Background bar from 100 to 0
      geom_rect(aes(xmin = 0, xmax = 100, ymin = 0.98, ymax = 1.02), fill = "#0A9396", alpha = 0.4) +
      # Vertical line for the gene score
      geom_vline(aes(xintercept = gene_score), color = "red", linewidth = 3) +
      # Text annotation for the score
      annotate("text", x = gene_score, y = 1, label = round(gene_score, 2),
               color = "black", size = 6, hjust = -0.2) +
      # Styling and labels
      labs(
        title = paste("Pan-Cancer Score of", gene),
        x = "Pan-Cancer Score (%)",
        y = NULL
      ) +
      coord_cartesian(xlim = c(-20, 120)) +
      scale_x_continuous(limits = c(0, 100), expand = c(0, 0), breaks = seq(0, 100, by = 25)) +
      scale_y_continuous(limits = c(0.98, 1.02)) +  # Reduce the height of the y-axis
      theme_void() +
      theme(
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        plot.title = element_text(hjust = 0.5, size = 16),
        axis.text.x = element_text(size = 12),
        plot.margin = margin(5, 10, 5, 10)  # Reduce margins to save space
      )
  }
}
