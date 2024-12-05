# Load the RDS files
data <- readRDS(url("https://github.com/ingmbioinfo/cancerhubs/raw/refs/heads/main/result/all_results.rds"))
interactors <- readRDS(url("https://github.com/ingmbioinfo/cancerhubs/raw/refs/heads/main/data/biogrid_interactors"))