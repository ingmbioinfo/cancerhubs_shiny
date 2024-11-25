<img src="cancerhubs_logo.png" align="right" alt="" width="200" />


# CancerHubs Data Explorer

Welcome to the **CancerHubs Data Explorer**! This Shiny application provides an interactive interface for exploring [Cancerhubs results](https://github.com/ingmbioinfo/cancerhubs), including viewing dataframes and examining gene rankings across various tumor types. This guide will walk you through setting up the app and navigating its features.

## Features
- **View Dataframes**: Explore different cancer datasets, filter by cancer type, and download the data for further analysis.
- **Gene Ranking Analysis**: Enter a gene name to see its ranking across different cancer types and subsets, visualize the rankings, and download both plots and tables for reference.

## Prerequisites
To run this Shiny application, you will need:
- **R** installed on your machine.
- The following R packages:
  - `shiny`
  - `ggplot2`
  - `openxlsx`
  - `DT`

## Installation
1. **Clone the repository**:
   ```sh
   git clone https://github.com/your_username/CancerHubsDataExplorer.git
   ```

2. **Install required R packages (if needed)**:
   Open R or RStudio and run the following commands:
   ```r
   install.packages("shiny")
   install.packages("ggplot2")
   install.packages("openxlsx")
   install.packages("DT")
   ```

3. **Load the data**:
   Make sure you have the `all_results` RDS file in the working directory or update the path to point to its location.

## Running the App
To run the Shiny app, open R or RStudio and execute the following commands:

```r
library(shiny)
runApp("path/to/CancerHubsDataExplorer")
```

Replace `"path/to/CancerHubsDataExplorer"` with the actual path to the folder where you cloned the repository.

## User Interface Walkthrough

### 1. View Dataframe Tab
In the **View Dataframe** tab, you can:
- **Select Cancer Type**: Choose from various cancer types available in the dataset.
- **Select Dataframe**: Choose between different subsets of the data, such as "All Genes", "PRECOG", "Non PRECOG", or "Only PRECOG".
- **View Data**: View the selected dataset in an interactive table with pagination and scrolling.
- **Download Data**: Download the displayed dataframe as an Excel file by clicking the "Download Dataframe (XLSX)" button.

### 2. Gene Ranking Tab
In the **Gene Ranking** tab, you can:
- **Enter Gene Name**: Input the name of the gene you are interested in (e.g., "TP53").
- **Select Dataframe Subset**: Choose the subset for ranking analysis (e.g., "All Genes", "PRECOG").
- **View Rankings**: See the ranking of the gene across various cancer types in an interactive table.
- **Download Ranking Table**: Download the ranking information as an Excel file.
- **View Ranking Plot**: Visualize the gene's rank across different tumor types.
- **Download Plot**: Download the ranking plot as a PDF file.

## Application Styling
The user interface uses a custom CancerHubs-inspired color palette:
- **Background**: Light blue tones for a calming interface.
- **Primary Text**: Dark blue for readability.
- **Accent Elements**: Teal and aqua for visual highlights, buttons, and header text.

The UI components include:
- A **Sidebar Panel** for user inputs, with dropdown menus and text inputs for filtering the data.
- A **Main Panel** that displays the data and plots, with tabs for easy navigation.

## Code Overview
The application has two primary components:
1. **UI Definition** (`ui`): Defines the layout, input elements, and overall styling of the application.
2. **Server Logic** (`server`): Defines the interactive behavior, such as rendering tables, generating plots, and providing downloads.

The server logic relies heavily on **reactive functions** to update the outputs dynamically based on user inputs. The application includes several download handlers that allow users to download dataframes, ranking tables, and plots for offline analysis.

## Example Usage
- To view the list of genes for a specific cancer type, navigate to the **View Dataframe** tab, select your desired **Cancer Type** and **Dataframe**, and explore the data.
- To explore the ranking of a specific gene, go to the **Gene Ranking** tab, enter the gene name, select the appropriate subset, and check the ranking table and plot.

## Contributing
If you wish to contribute to the project, feel free to fork the repository and submit a pull request. We welcome improvements and suggestions to enhance the user experience and data visualization features.

## License
This project is licensed under the MIT License. See the LICENSE file for more details.

## Funding
This research was funded by Associazione Italiana per la Ricerca sul Cancro (AIRC), under MFAG 2021 ID 26178 project to Nicola Manfrini.

## Contact
For questions or support, please contact manfrini@ingm.org, ferrari@ingm.org or arsuffi@ingm.org. 

## Citation
If you use CancerHubs in your research, please cite our paper:

Ivan Ferrari, Giancarlo Lai, Federica De Grossi, Stefania Oliveto, Stefano Biffo, Nicola Manfrini. "CancerHubs: A Systematic Data Mining and Elaboration Approach for Identifying Novel Cancer-Related Protein Interaction Hubs." [Journal, Volume, Year].
