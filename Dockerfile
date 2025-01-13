# Use the official R base image
FROM rocker/shiny:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libxt-dev \
    && apt-get clean

# Install R packages required by the app
RUN R -e "install.packages(c('shiny', 'cowplot', 'ggplot2', 'openxlsx', 'DT', 'purrr', 'igraph', 'plotly', 'RColorBrewer', 'dplyr', 'tidyr'), dependencies=TRUE)"

# Copy the application files to the Docker image
WORKDIR /srv/shiny-server
COPY . .

# Expose the Shiny server port
EXPOSE 3838

# Run the Shiny app
CMD ["R", "-e", "shiny::runApp('/srv/shiny-server')"]
