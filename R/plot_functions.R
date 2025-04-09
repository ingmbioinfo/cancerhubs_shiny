
to_ordinal_expression_text <- function(x) {
  if (x %% 100 %in% 11:13) {
    suffix <- "th"
  } else {
    suffix <- switch(as.character(x %% 10),
                     "1" = "st", "2" = "nd", "3" = "rd", "th")
  }
  paste0(x, "^\"", suffix, "\"")
}




create_ranking_plot <- function(rankings, gene, dataframe_subset) {
  if (nrow(rankings) == 0) {
    plot(1, type = "n", xlab = "", ylab = "", main = "Gene not found in any tumor type")
  } else {
    rankings$label_text <- mapply(function(rank, total) {
      paste0(to_ordinal_expression_text(rank), " ~ '/' ~ ", total)
    }, rankings$Rank, rankings$TotalGenes)
    
    mean_rank <- mean(rankings$Rank)
    
    # Identify the row with the minimum rank
    min_rank_idx <- which.min(rankings$Rank)
    rankings$IsMin <- FALSE
    rankings$IsMin[min_rank_idx] <- TRUE
    
    ggplot(rankings, aes(y = reorder(Tumor, -Rank), x = Rank)) +
      geom_vline(xintercept = mean_rank, linetype = "dotted", color = "black") + 
      
      geom_segment(aes(xend = mean_rank, yend = reorder(Tumor, -Rank), color = Rank), 
                   size = 0.8, show.legend = FALSE) +
      
      # Regular points (no border)
      geom_point(
        data = subset(rankings, !IsMin),
        aes(fill = Rank),
        shape = 21, size = 7, color = "transparent"
      )  +
      
      # Point with min rank (black border)
      geom_point(data = subset(rankings, IsMin),
                 aes(fill = Rank),
                 shape = 21, size = 7, color = "black", stroke = 1.2, show.legend = FALSE) +
      
      geom_text(aes(label = label_text), hjust = -0.2, vjust = -1.1, size = 4, parse = TRUE, show.legend = FALSE) +
      annotate("text", x = mean_rank - 0.1, y = 0.2, label = "Mean Rank", 
               vjust = -0.5, hjust = 0, size = 4, color = "black") +
      
      scale_fill_gradient(low = "#0A9396", high = "#EEA2AD") +
      scale_color_gradient(low = "#0A9396", high = "#EEA2AD") +
      scale_x_reverse(expand = expansion(mult = c(0.05, 0.4))) +
      
      
      
      labs(
        title = paste("Ranking of", gene, "in", gsub("_", " ", dataframe_subset)),
        y = "Tumor Type",  
        x = "Rank (1 = Highest Rank)", 
        fill = "Rank in tumors"
      ) +
      theme_classic() +
      theme(
        axis.text.y = element_text(size = 12, angle = 0, hjust = 1), 
        axis.text.x = element_text(size = 12),
        plot.title = element_text(hjust = 0.5, size = 16),
        panel.grid.major.y = element_line(color = "#dfe6ec", linetype = 2),
        legend.position = "bottom",
        plot.margin = margin(10, 20, 10, 10)
      ) +
      guides(
        fill = guide_colorbar(
          title.position = "top",
          title.hjust = 0.5,
          barwidth = unit(6, "cm"),   # wider/longer bar
          barheight = unit(0.7, "cm") # thicker/taller bar
        )
      )
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
    ggplot() +  #826B7F
      # Background bar from 100 to 0
      geom_rect(aes(xmin = 0, xmax = 100, ymin = 0.98, ymax = 1.02), fill = "#CFEAF7", alpha = 1) +
      # Vertical line for the gene score
      # Black outline vline
      geom_vline(aes(xintercept = gene_score), color = "#1B4F72", linewidth = 4) +
      # Pink inner vline
      geom_vline(aes(xintercept = gene_score), color = "#1B4F72", linewidth = 3) +
      # Text annotation for the score
      annotate("text", x = gene_score, y = 1, label = round(gene_score, 2),
               color = "black", size = 5, hjust = -0.2) +
      # Styling and labels
      labs(
        title = paste("Pan-Cancer Score of", gene),
        x = "Pan-Cancer Score (%)",
        y = NULL
      ) +
      coord_cartesian(xlim = c(-20, 120))+
      scale_x_continuous(limits = c(-20, 120), expand = c(0, 0), breaks = seq(0, 100, by = 25)) +
      scale_y_continuous(limits = c(0.98, 1.02)) +  # Reduce the height of the y-axis
      theme_void() +
      theme(
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        axis.text.x = element_text(size = 12),
        plot.margin = margin(5, 150, 5, 270),  # Reduce margins to save space
        plot.title = element_text(hjust = 0.5, size = 16, margin = margin(t = 0, b = 20))
      )
  }
}
