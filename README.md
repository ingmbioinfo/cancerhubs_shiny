<img src="www/cancerhubs_logo.png" align="right" alt="CancerHubs Logo" width="200" />

# CancerHubs Data Explorer

## Overview

The **CancerHubs Data Explorer** is an interactive Shiny web application built on the *CancerHubs* framework — a network-based strategy to prioritise genes based on the number and type of mutated interactors in tumour-specific protein–protein interaction networks. Unlike traditional tools that rely solely on mutation frequency or expression changes, CancerHubs highlights genes that act as central coordinators of oncogenic processes.

To support this goal, each gene is assigned a **Network Score** measuring its embedding in networks of cancer-mutated partners. Genes are also annotated with prognostic information from the PRECOG database, enabling users to explore cancer hubs with mutation and survival relevance.

The Data Explorer provides interactive access to this resource through:
- Tumour-specific gene tables
- Interactive plots for gene ranking
- Cross-tumour comparison tools
- 2D and 3D network visualisations

Designed for researchers with or without coding experience, the app simplifies the identification and export of candidate genes and network modules for further study.

🧪 **Live App**: [https://cancerhubs.app/](https://cancerhubs.app/)  
📦 **Cancerhubs Main Repository**: [https://github.com/ingmbioinfo/cancerhubs](https://github.com/ingmbioinfo/cancerhubs)

---

## 🔍 Features

- **View Dataframe**  
  Browse gene-level results per tumour type. Filter by evidence category, sort by any metric, search by gene symbol, and download custom tables.

- **Gene Ranking**  
  Investigate the ranking of any gene across tumour types based on its Network Score. Includes lollipop plots and interactive tables.

- **Common Genes**  
  Identify genes that rank highly in multiple tumours. A heatmap and downloadable table show recurrence patterns across datasets.

- **Network Plot (3D)**  
  Interactive 3D network showing top genes in a tumour, coloured by score or prognosis. Built using BioGRID data.

- **Gene Network (2D)**  
  View the interactome of any gene. A radial 2D layout shows mutated or PRECOG-significant interactors, with download options.

### Gene Subsets and Network Score

The app organises genes into four evidence-driven categories:

- **All Genes** – every scored gene that is either mutated or has prognostic relevance.
- **Only Mutated** – genes harbouring mutations but lacking significant PRECOG scores (|meta-Z| < 1.96).
- **PRECOG** – genes with significant prognostic association (|meta-Z| ≥ 1.96) regardless of mutation status.
- **Only PRECOG** – genes with |meta-Z| ≥ 2.58 that are not mutated in the selected dataset.

Each gene receives a **Network Score** measuring the fraction of its interactors that are mutated:

```
Network Score = (# Mutated Interactors)^2 / (# Total Interactors)
```

This score captures the degree to which a gene is embedded in a tumour-specific network of mutated partners. Genes with high scores may represent critical hubs in cancer-related processes.
> **Note:** The Network Score is based exclusively on somatic mutation data and does **not** incorporate copy-number variations.

---

## 🛠️ Prerequisites

To run this app locally, ensure you have:

- **R** (≥ 4.0.0)
- These R packages:
  ```r
  install.packages(c(
    "shiny", "ggplot2", "openxlsx", "DT", "plotly",
    "igraph", "RColorBrewer", "cowplot", "purrr",
    "dplyr", "tidyr", "shinycssloaders", "shinyjs"
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

## 📁 Documentation
- Full guide available here: [`USER_MANUAL.pdf`](USER_MANUAL.pdf)  
  Includes screenshots and detailed usage instructions for each feature of the app.

---

## 🤝 Data

All datasets are fetched from the main [CancerHubs GitHub repository](https://github.com/ingmbioinfo/cancerhubs):

- [`all_results.rds`](https://github.com/ingmbioinfo/cancerhubs/blob/main/result/all_results.rds) – output of the network-based prioritisation algorithm, providing gene-wise scores per tumour type.
- [`genes_interactors_list.rds`](https://github.com/ingmbioinfo/cancerhubs/blob/main/result/genes_interactors_list.rds) – precompiled map of all interactors for each gene.
- [`formatted_datasets`](https://github.com/ingmbioinfo/cancerhubs/tree/main/data/formatted_datasets) – preprocessed input data tables per tumour.
- [`biogrid_interactors`](https://github.com/ingmbioinfo/cancerhubs/blob/main/data/biogrid_interactors) – full BioGRID-derived protein interaction data.
- [`Mutational Data Summary`](https://github.com/ingmbioinfo/cancerhubs/blob/main/Mutational%20Data.pdf) – PDF describing mutation annotation sources, filtering rules, and dataset details.

---

## 🛠️ Troubleshooting

| Problem                 | Solution                                                                 |
|------------------------|--------------------------------------------------------------------------|
| No results found       | Make sure the gene symbol exists and matches the dataset.               |
| Slow network rendering | Reduce the number of genes or interactions shown.                       |
| Page not loading       | Check your internet connection and reload the browser.                  |

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

---

## 🎯 Use Cases

- Discover tumour-specific protein hubs not evident from mutation frequency alone
- Compare gene ranks across cancer types with interactive plots
- Export network data for integration into publications or follow-up pipelines
