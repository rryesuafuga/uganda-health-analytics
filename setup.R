# setup.R
packages <- c(
  "shiny", "shinydashboard", "shinyjs", "shinycssloaders",
  "plotly", "dplyr", "tidyr", "ggplot2", "DT",
  "glmnet", "MatchIt", "randomForest", "leaflet",
  "visNetwork", "data.table", "memoise", "future",
  "promises", "cachem"
)

for (pkg in packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.rstudio.com/")
  }
}
