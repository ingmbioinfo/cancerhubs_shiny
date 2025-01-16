# Use the official R base image
FROM rocker/shiny:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libxt-dev \
    libglpk40 \
    libpq-dev \
    && apt-get clean

# Install R packages required by the app
RUN R -e "install.packages(c('shiny', 'cowplot', 'ggplot2', 'openxlsx', 'DT', 'purrr', 'igraph', 'plotly', 'RColorBrewer', 'dplyr', 'tidyr'), dependencies=TRUE)"
RUN R -e "install.packages('RPostgreSQL', dependencies=TRUE)"

# Copy all app files into the container
COPY . /srv/shiny-server/

# Set the working directory for subsequent commands
WORKDIR /srv/shiny-server

# Expose the fixed Shiny server port
EXPOSE 3838

# Run the Shiny app on a fixed port and make it accessible externally
CMD ["R", "-e", "shiny::runApp('/srv/shiny-server', port = 3838, host = '0.0.0.0')"]
