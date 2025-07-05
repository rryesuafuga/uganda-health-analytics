# Activate renv
source("renv/activate.R")

# Set CRAN repository
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Ensure shiny is available when the app starts
.First <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    utils::install.packages("shiny")
  }
  if (!requireNamespace("shinydashboard", quietly = TRUE)) {
    utils::install.packages("shinydashboard")
  }
}
