FROM rocker/shiny:4.4.0

# Install system dependencies (including those needed for leaflet/visNetwork)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libudunits2-dev \
    libv8-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# Set CRAN mirror and use multiple cores for compilation
ENV MAKEFLAGS="-j2"

# Install R packages in groups to catch failures early
RUN R -e "options(repos='https://cloud.r-project.org/', Ncpus=2); install.packages(c('shiny', 'shinydashboard', 'shinyjs', 'shinycssloaders'))"
RUN R -e "options(repos='https://cloud.r-project.org/', Ncpus=2); install.packages(c('plotly', 'dplyr', 'tidyr', 'ggplot2', 'DT'))"
RUN R -e "options(repos='https://cloud.r-project.org/', Ncpus=2); install.packages(c('glmnet', 'MatchIt', 'randomForest'))"
RUN R -e "options(repos='https://cloud.r-project.org/', Ncpus=2); install.packages('htmlwidgets')"
RUN R -e "options(repos='https://cloud.r-project.org/', Ncpus=2); install.packages('leaflet')"
RUN R -e "options(repos='https://cloud.r-project.org/', Ncpus=2); install.packages('visNetwork')"
RUN R -e "options(repos='https://cloud.r-project.org/', Ncpus=2); install.packages(c('data.table', 'memoise', 'cachem', 'future', 'promises'))"

# Verify all critical packages are installed
RUN R -e "pkgs <- c('shiny','shinydashboard','shinyjs','shinycssloaders','plotly','dplyr','tidyr','ggplot2','DT','glmnet','MatchIt','randomForest','leaflet','visNetwork','data.table','memoise','cachem','future','promises'); missing <- pkgs[!sapply(pkgs, requireNamespace, quietly=TRUE)]; if(length(missing)>0) stop(paste('Missing packages:', paste(missing, collapse=', ')))"

# Create app directory
RUN mkdir -p /app

# Copy application files
COPY app.R /app/
COPY global.R /app/
COPY setup.R /app/
COPY dependencies.R /app/
COPY install_packages.R /app/
COPY modules/ /app/modules/
COPY data/ /app/data/
COPY www/ /app/www/

WORKDIR /app

# Hugging Face Spaces uses port 7860
EXPOSE 7860

# Set environment variables for Hugging Face
ENV PORT=7860
ENV HOST=0.0.0.0

# Run the Shiny app
CMD ["R", "-e", "shiny::runApp('/app', host='0.0.0.0', port=7860)"]
