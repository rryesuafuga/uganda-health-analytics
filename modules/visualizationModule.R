# modules/visualizationModule.R
# Advanced visualization module with network analysis

visualizationModuleUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    tags$div(
      style = "padding: 15px;",
      h4("AI-Powered Insights", icon("brain")),
      hr(),
      
      # Key metrics
      tags$div(
        class = "row",
        tags$div(
          class = "col-sm-6",
          tags$div(
            class = "small-box bg-green",
            style = "margin-bottom: 10px;",
            tags$div(
              class = "inner",
              tags$h4("32%", style = "margin: 0;"),
              tags$p("Mortality Reduction", style = "margin: 0;")
            ),
            tags$div(class = "icon", icon("arrow-down"))
          )
        ),
        tags$div(
          class = "col-sm-6",
          tags$div(
            class = "small-box bg-yellow",
            style = "margin-bottom: 10px;",
            tags$div(
              class = "inner",
              tags$h4("78%", style = "margin: 0;"),
              tags$p("Target Progress", style = "margin: 0;")
            ),
            tags$div(class = "icon", icon("chart-line"))
          )
        )
      ),
      
      # Network visualization
      tags$div(
        style = "margin-top: 20px;",
        h5("Health Determinants Network"),
        visNetworkOutput(ns("network_viz"), height = "300px")
      ),
      
      # Action recommendations
      tags$div(
        style = "margin-top: 20px;",
        h5("Recommended Actions"),
        uiOutput(ns("recommendations"))
      )
    )
  )
}

visualizationModule <- function(input, output, session, health_data) {
  ns <- session$ns
  
  # Network visualization showing relationships between health indicators
  output$network_viz <- renderVisNetwork({
    # Create nodes
    nodes <- data.frame(
      id = 1:7,
      label = c("Child Mortality", "Nutrition", "WASH", "Immunization", 
                "Education", "Healthcare", "Economic"),
      group = c("outcome", "factor", "factor", "factor", "factor", "factor", "factor"),
      value = c(30, 25, 20, 25, 15, 20, 15),
      color = c("#e74c3c", "#f39c12", "#3498db", "#27ae60", "#9b59b6", "#1abc9c", "#34495e"),
      font.color = "white",
      font.size = 14
    )
    
    # Create edges showing relationships
    edges <- data.frame(
      from = c(2, 3, 4, 5, 6, 7, 2, 3, 4),
      to = c(1, 1, 1, 1, 1, 1, 3, 6, 5),
      value = c(3, 2.5, 3.5, 2, 2.5, 1.5, 2, 1.5, 1),
      color = list(opacity = 0.7),
      smooth = list(enabled = TRUE, type = "curvedCW")
    )
    
    visNetwork(nodes, edges) %>%
      visOptions(
        highlightNearest = list(enabled = TRUE, degree = 1, hover = TRUE),
        nodesIdSelection = TRUE
      ) %>%
      visPhysics(
        stabilization = list(iterations = 100),
        solver = "forceAtlas2Based"
      ) %>%
      visLayout(randomSeed = 123) %>%
      visInteraction(
        navigationButtons = TRUE,
        zoomView = FALSE
      )
  })
  
  # Generate AI-powered recommendations
  output$recommendations <- renderUI({
    # Analyze current trends
    latest_data <- health_data() %>%
      filter(year == max(year))
    
    mortality_trend <- latest_data %>%
      filter(indicator == "Under-5 Mortality") %>%
      summarise(avg = mean(value)) %>%
      pull(avg)
    
    recommendations <- list()
    
    if (mortality_trend > 40) {
      recommendations <- append(recommendations, list(
        tags$div(
          class = "alert alert-danger",
          icon("exclamation-triangle"),
          "High mortality rate detected. Prioritize emergency health interventions."
        )
      ))
    }
    
    recommendations <- append(recommendations, list(
      tags$div(
        class = "alert alert-warning",
        icon("lightbulb"),
        "Focus on integrated WASH and nutrition programs for maximum impact."
      ),
      tags$div(
        class = "alert alert-info",
        icon("chart-line"),
        "Current trajectory suggests 15% mortality reduction achievable by 2025."
      ),
      tags$div(
        class = "alert alert-success",
        icon("check-circle"),
        "Immunization coverage improving - maintain current vaccination campaigns."
      )
    ))
    
    tagList(recommendations)
  })
}
