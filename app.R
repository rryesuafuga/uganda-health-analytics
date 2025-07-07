library(shiny)

ui <- fluidPage(
  h1("Uganda Health Analytics - Test"),
  p("If you see this, deployment is working!")
)

server <- function(input, output, session) {
  # Empty server
}

shinyApp(ui = ui, server = server)
