# .Rprofile
source("renv/activate.R")

# Ensure critical packages are installed
if (!requireNamespace("shiny", quietly = TRUE)) {
  install.packages("shiny")
}
if (!requireNamespace("shinydashboard", quietly = TRUE)) {
  install.packages("shinydashboard")
}
