# Install required packages
packages <- c(
  "shiny",
  "shinydashboard", 
  "shinyjs",
  "shinycssloaders",
  "plotly",
  "dplyr",
  "tidyr",
  "ggplot2",
  "DT",
  "glmnet",
  "MatchIt",
  "randomForest",
  "leaflet",
  "visNetwork",
  "data.table",
  "memoise",
  "future",
  "promises",
  "cachem"
)

# Install packages not already installed
install_if_missing <- function(pkg) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
  }
}

lapply(packages, install_if_missing)
