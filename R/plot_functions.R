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
        axis.text.x = element_text(size = 12),
        plot.title = element_text(hjust = 0.5, size = 14),
        panel.grid.major = element_line(color = "#dfe6ec"),
        legend.position = "bottom",
        plot.margin = margin(10, 40, 10, 10)
      ) +
      guides(color = guide_legend(override.aes = list(size = 5, shape = 16)))
  }
}
