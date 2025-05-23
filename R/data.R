# Define a safe function to load RDS from a URL and close the connection
load_remote_rds <- function(remote_url) {
  con <- url(remote_url, "rb")
  on.exit(close(con))
  readRDS(con)
}

# Use the function to load each dataset
data <- load_remote_rds("https://github.com/ingmbioinfo/cancerhubs/raw/refs/heads/main/result/all_results.rds")
interactors <- load_remote_rds("https://github.com/ingmbioinfo/cancerhubs/raw/refs/heads/main/data/biogrid_interactors")
gene_interactors <- load_remote_rds("https://github.com/ingmbioinfo/cancerhubs/raw/refs/heads/main/result/genes_interactors_list.rds")
