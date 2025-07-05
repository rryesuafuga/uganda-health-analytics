# install_packages.R
packages <- c(
  "shiny", "shinydashboard", "shinyjs", "shinycssloaders",
  "plotly", "dplyr", "tidyr", "ggplot2", "DT",
  "glmnet", "MatchIt", "randomForest", "leaflet", 
  "visNetwork", "data.table", "memoise", "future", 
  "promises", "cachem"
)

install.packages(packages)
