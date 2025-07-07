# Run setup if packages are missing
if (!requireNamespace("shiny", quietly = TRUE)) {
  source("setup.R")
}

library(shiny)

ui <- fluidPage(
  h1("Test Deployment"),
  p("If you see this, packages are loading correctly!")
)

server <- function(input, output) {}

shinyApp(ui, server)
