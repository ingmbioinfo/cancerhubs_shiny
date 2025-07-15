<img src="www/cancerhubs_logo.png" align="right" alt="CancerHubs Logo" width="200" />

# CancerHubs Data Explorer

Welcome to the **CancerHubs Data Explorer**!  
This Shiny application provides an interactive interface for exploring results from the [CancerHubs project](https://github.com/ingmbioinfo/cancerhubs), including ranked gene data across tumour types, network visualisations, and shared hubs.

🧪 **Live App**: [https://cancerhubs.app/](https://cancerhubs.app/)  
📦 **Cancerhubs Main Repository**: [https://github.com/ingmbioinfo/cancerhubs](https://github.com/ingmbioinfo/cancerhubs)

---

## 🔍 Features

- **View Dataframe**
  Explore pre-processed gene tables for each tumour type. Choose between _All Genes_, _PRECOG_, _Only Mutated_, and _Only PRECOG_ subsets. Download filtered data as Excel.

- **Gene Ranking**
  Input a gene symbol to check its rank across cancers based on **Network Score**. Visualise and download the results, including a pan-cancer positioning plot.

- **Common Genes**
  Identify genes that consistently rank in the top N positions across multiple tumours. View results in a dynamic heatmap and export them.

- **Network Plot (3D)**  
  Visualise a 3D network of the top-scoring genes in a tumour dataset. Interactions are mapped based on known BioGRID interactions. Node colour, shape, and size encode multiple annotations.

- **Gene Network (2D)**
  Explore direct interactors of any gene of interest. Visualise up to 50 interactors with igraph-style layout and download both the network image and tables.

### Gene Subsets and Network Score

The app organises genes into four evidence-driven categories:

- **All Genes** – every scored gene that is either mutated or has prognostic relevance.
- **Only Mutated** – genes harbouring mutations but lacking significant PRECOG scores (|meta-Z| < 1.96).
- **PRECOG** – genes with significant prognostic association (|meta-Z| ≥ 1.96) regardless of mutation status.
- **Only PRECOG** – genes with |meta-Z| ≥ 1.96 that are not mutated in the selected dataset.

Each gene receives a **Network Score** measuring the fraction of its interactors that are mutated:

```
Network Score = (# Mutated Interactors) / (# Total Interactors)
```

This metric does not include copy-number variations. High scores highlight potential hubs driving oncogenic processes.

---

## 🛠️ Prerequisites

To run this app locally, ensure you have:

- **R** (≥ 4.0.0)
- These R packages:
  ```r
  install.packages(c(
    "shiny", "ggplot2", "openxlsx", "DT", "plotly",
    "igraph", "RColorBrewer", "cowplot", "purrr",
    "dplyr", "tidyr", "shinycssloaders"
  ))
  ```

---

## 💾 Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/ingmbioinfo/cancerhubs_shiny.git
   ```

2. **Run the App**:
   Open R or RStudio and run:
   ```r
   library(shiny)
   runApp("path/to/cancerhubs_shiny")
   ```

---

## 🌐 Online Access

You can use the app directly online without installation:  
👉 [https://cancerhubs.app/](https://cancerhubs.app/)

## 📑 Documentation
- [PDF Manual](USER_MANUAL.pdf)

---

## 🧬 Data

All datasets are fetched directly from the main CancerHubs repository:

> **Note**: The *Network Score* is based solely on somatic mutation data and does **not** incorporate copy-number variations.

- [`all_results.rds`](https://github.com/ingmbioinfo/cancerhubs/blob/main/result/all_results.rds) – analysis output providing scores for each gene across cancer types.
- [`genes_interactors_list.rds`](https://github.com/ingmbioinfo/cancerhubs/blob/main/result/genes_interactors_list.rds) – curated gene list with all corresponding interactors.
- *Formatted datasets* – preprocessed input tables compiled from literature sources.
- [`biogrid_interactors`](https://github.com/ingmbioinfo/cancerhubs/blob/main/data/biogrid_interactors) – full interaction records from BioGRID.
- *Mutational Data Summary* – PDF describing the literature sources used for mutation data extraction.

---

### Troubleshooting

If the app fails to return results, double-check the gene symbol and try reducing the number of genes or interactors shown. More hints are available in the [PDF Manual](USER_MANUAL.pdf).

---

## 🙋‍♀️ Contact

For questions or support, contact:

- Nicola Manfrini – `manfrini@ingm.org`
- Ivan Ferrari – `ferrari@ingm.org`
- Elisa Arsuffi – `arsuffi@ingm.org`

---

## 📖 Citation

If you use CancerHubs in your research, please cite:

> Ivan Ferrari, Federica De Grossi, Giancarlo Lai, Stefania Oliveto, Giorgia Deroma, Stefano Biffo, Nicola Manfrini.  
> **CancerHubs: a systematic data mining and elaboration approach for identifying novel cancer-related protein interaction hubs**.  
> _Briefings in Bioinformatics_, Volume 26, Issue 1, January 2025.  
> [https://doi.org/10.1093/bib/bbae635](https://doi.org/10.1093/bib/bbae635)

---

## 📜 License

MIT License.  
© 2024 Istituto Nazionale di Genetica Molecolare (INGM).

---

## 💸 Funding

This research was funded by the **Associazione Italiana per la Ricerca sul Cancro (AIRC)**, under **MFAG 2021 ID 26178** project to **Nicola Manfrini**.
