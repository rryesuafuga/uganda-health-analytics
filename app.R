# Ensure required packages are loaded
if (!require("shiny", quietly = TRUE)) {
  install.packages("shiny", repos = "https://cran.rstudio.com/")
  library(shiny)
}
if (!require("shinydashboard", quietly = TRUE)) {
  install.packages("shinydashboard", repos = "https://cran.rstudio.com/")
  library(shinydashboard)
}


# app.R - Uganda Child Health Analytics Dashboard
# World Vision Focus Area: Child Health & Mortality with Nutrition Integration

library(shiny)
library(shinydashboard)
library(shinyjs)
library(shinycssloaders)
library(plotly)
library(dplyr)
library(tidyr)
library(ggplot2)
library(DT)
library(glmnet)
library(MatchIt)
library(randomForest)
library(leaflet)
library(visNetwork)

# Source modules
source("modules/dataModule.R")
source("modules/analysisModule.R")
source("modules/visualizationModule.R")
source("modules/modelingModule.R")

# Custom CSS
custom_css <- "
/* Modern Design System */
:root {
  --primary-color: #FF6200;
  --secondary-color: #0095DA;
  --success-color: #52C41A;
  --warning-color: #FAAD14;
  --danger-color: #F5222D;
  --dark-bg: #001529;
  --light-bg: #F0F2F5;
  --card-shadow: 0 2px 8px rgba(0,0,0,0.09);
  --hover-shadow: 0 4px 12px rgba(0,0,0,0.15);
}

/* Animated Background */
body {
  background: linear-gradient(-45deg, #ee7752, #e73c7e, #23a6d5, #23d5ab);
  background-size: 400% 400%;
  animation: gradient 15s ease infinite;
}

@keyframes gradient {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}

/* Glassmorphism Cards */
.box {
  background: rgba(255, 255, 255, 0.9);
  backdrop-filter: blur(10px);
  border-radius: 15px;
  border: 1px solid rgba(255, 255, 255, 0.3);
  box-shadow: var(--card-shadow);
  transition: all 0.3s ease;
}

.box:hover {
  transform: translateY(-5px);
  box-shadow: var(--hover-shadow);
}

/* Custom Header */
.main-header {
  background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.main-header .logo {
  font-weight: 700;
  letter-spacing: 1px;
  text-transform: uppercase;
}

/* Sidebar Styling */
.main-sidebar {
  background-color: var(--dark-bg);
  box-shadow: 2px 0 4px rgba(0,0,0,0.1);
}

.sidebar-menu > li > a {
  border-left: 3px solid transparent;
  transition: all 0.3s ease;
}

.sidebar-menu > li:hover > a,
.sidebar-menu > li.active > a {
  border-left-color: var(--primary-color);
  background-color: rgba(255, 98, 0, 0.1);
}

/* Value Boxes */
.small-box {
  border-radius: 10px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  box-shadow: var(--card-shadow);
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
}

.small-box::before {
  content: '';
  position: absolute;
  top: -50%;
  right: -50%;
  width: 200%;
  height: 200%;
  background: radial-gradient(circle, rgba(255,255,255,0.3) 0%, transparent 70%);
  transform: rotate(45deg);
  transition: all 0.5s ease;
}

.small-box:hover::before {
  top: -60%;
  right: -60%;
}

.small-box:hover {
  transform: scale(1.05);
  box-shadow: var(--hover-shadow);
}

/* Loading Animation */
.loading-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0,0,0,0.8);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 9999;
}

.loading-spinner {
  width: 60px;
  height: 60px;
  border: 3px solid rgba(255,255,255,0.3);
  border-radius: 50%;
  border-top-color: var(--primary-color);
  animation: spin 1s ease-in-out infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* Custom Buttons */
.btn-custom {
  background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
  color: white;
  border: none;
  border-radius: 25px;
  padding: 10px 25px;
  font-weight: 600;
  transition: all 0.3s ease;
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}

.btn-custom:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 12px rgba(0,0,0,0.15);
  color: white;
}

/* Data Table Styling */
.dataTables_wrapper {
  padding: 20px;
  background: rgba(255,255,255,0.9);
  border-radius: 10px;
}

table.dataTable thead {
  background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
  color: white;
}

/* Responsive Design */
@media (max-width: 768px) {
  .small-box h3 {
    font-size: 24px;
  }
  
  .box {
    margin-bottom: 20px;
  }
}
"

# Custom JavaScript
custom_js <- "
// Initialize tooltips and popovers
$(document).ready(function(){
  $('[data-toggle=\"tooltip\"]').tooltip();
  $('[data-toggle=\"popover\"]').popover();
  
  // Smooth scroll
  $('a[href*=\"#\"]:not([href=\"#\"])').click(function() {
    if (location.pathname.replace(/^\\//, '') == this.pathname.replace(/^\\//, '') && location.hostname == this.hostname) {
      var target = $(this.hash);
      target = target.length ? target : $('[name=' + this.hash.slice(1) + ']');
      if (target.length) {
        $('html, body').animate({
          scrollTop: target.offset().top
        }, 1000);
        return false;
      }
    }
  });
});

// Custom loading overlay
shinyjs.showLoading = function() {
  $('body').append('<div class=\"loading-overlay\"><div class=\"loading-spinner\"></div></div>');
};

shinyjs.hideLoading = function() {
  $('.loading-overlay').remove();
};

// Animated counter
shinyjs.animateCounter = function(params) {
  const element = $('#' + params.id);
  const endValue = params.value;
  const duration = params.duration || 2000;
  
  $({countNum: element.text()}).animate({countNum: endValue}, {
    duration: duration,
    easing: 'swing',
    step: function() {
      element.text(Math.floor(this.countNum));
    },
    complete: function() {
      element.text(this.countNum);
    }
  });
};

// Network visualization with D3
shinyjs.createNetwork = function(data) {
  // D3.js network visualization code
  const width = 800;
  const height = 600;
  
  const svg = d3.select('#network-viz')
    .append('svg')
    .attr('width', width)
    .attr('height', height);
    
  // Implementation continues...
};
"

# UI
ui <- dashboardPage(
  dashboardHeader(
    title = tags$span(
      icon("heart-pulse"),
      "Uganda Child Health Analytics"
    ),
    tags$li(class = "dropdown",
      tags$a(href = "#", class = "btn-custom", 
             onclick = "shinyjs.showLoading(); setTimeout(function(){ shinyjs.hideLoading(); }, 2000);",
             icon("download"), "Export Report")
    )
  ),
  
  dashboardSidebar(
    sidebarMenu(
      id = "sidebar",
      menuItem("Executive Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Health Indicators", tabName = "indicators", icon = icon("chart-line")),
      menuItem("Predictive Models", tabName = "models", icon = icon("brain")),
      menuItem("Causal Analysis", tabName = "causal", icon = icon("microscope")),
      menuItem("Intervention Planning", tabName = "intervention", icon = icon("hand-holding-medical")),
      menuItem("Data Explorer", tabName = "data", icon = icon("database"))
    ),
    
    # Quick Stats
    div(style = "padding: 20px;",
      h4("Quick Stats", style = "color: white; margin-bottom: 15px;"),
      tags$div(class = "info-box bg-red",
        span(class = "info-box-icon", icon("child")),
        div(class = "info-box-content",
          span(class = "info-box-text", "Under-5 Mortality"),
          span(class = "info-box-number", id = "mortality-stat", "43.0"),
          span(class = "info-box-text", "per 1,000 live births")
        )
      )
    )
  ),
  
  dashboardBody(
    useShinyjs(),
    tags$head(
      tags$style(HTML(custom_css)),
      tags$link(rel = "stylesheet", 
                href = "https://cdnjs.cloudflare.com/ajax/libs/animate.css/4.1.1/animate.min.css")
    ),
    extendShinyjs(text = custom_js, functions = c("showLoading", "hideLoading", 
                                                  "animateCounter", "createNetwork")),
    
    tabItems(
      # Executive Dashboard
      tabItem(
        tabName = "dashboard",
        fluidRow(
          valueBoxOutput("mortality_box"),
          valueBoxOutput("malnutrition_box"),
          valueBoxOutput("immunization_box")
        ),
        
        fluidRow(
          box(
            title = "Child Health Trends (2010-2023)",
            status = "primary",
            solidHeader = TRUE,
            width = 8,
            dataModuleUI("main_data")
          ),
          
          box(
            title = "Key Insights",
            status = "warning",
            width = 4,
            visualizationModuleUI("insights")
          )
        ),
        
        fluidRow(
          box(
            title = "Regional Health Map",
            width = 12,
            leafletOutput("health_map", height = "400px")
          )
        )
      ),
      
      # Health Indicators
      tabItem(
        tabName = "indicators",
        analysisModuleUI("health_analysis")
      ),
      
      # Predictive Models
      tabItem(
        tabName = "models",
        modelingModuleUI("predictive_models")
      ),
      
      # Causal Analysis
      tabItem(
        tabName = "causal",
        fluidRow(
          box(
            title = "Propensity Score Matching Analysis",
            width = 12,
            solidHeader = TRUE,
            status = "info",
            
            fluidRow(
              column(4,
                selectInput("psm_treatment", "Select Intervention:",
                           choices = c("Nutrition Program" = "nutrition",
                                     "WASH Improvement" = "wash",
                                     "Vaccination Campaign" = "vaccine")),
                selectInput("psm_outcome", "Outcome Variable:",
                           choices = c("Child Mortality" = "mortality",
                                     "Stunting Reduction" = "stunting",
                                     "Disease Incidence" = "disease")),
                actionButton("run_psm", "Run Analysis", class = "btn-custom btn-block")
              ),
              column(8,
                withSpinner(plotOutput("psm_results", height = "400px"))
              )
            )
          )
        )
      ),
      
      # Intervention Planning
      tabItem(
        tabName = "intervention",
        fluidRow(
          box(
            title = "Intervention Simulator",
            width = 12,
            
            fluidRow(
              column(4,
                h4("Configure Intervention"),
                sliderInput("int_coverage", "Population Coverage (%):",
                           min = 10, max = 100, value = 50, step = 5),
                sliderInput("int_budget", "Budget (Million USD):",
                           min = 1, max = 50, value = 10, step = 1),
                selectInput("int_type", "Intervention Type:",
                           choices = c("Integrated" = "integrated",
                                     "Nutrition-focused" = "nutrition",
                                     "WASH-focused" = "wash",
                                     "Health Systems" = "health")),
                actionButton("simulate", "Simulate Impact", 
                            class = "btn-custom btn-block",
                            icon = icon("rocket"))
              ),
              column(8,
                withSpinner(plotlyOutput("intervention_impact", height = "400px")),
                br(),
                verbatimTextOutput("impact_summary")
              )
            )
          )
        )
      ),
      
      # Data Explorer
      tabItem(
        tabName = "data",
        fluidRow(
          box(
            title = "Data Explorer",
            width = 12,
            DT::dataTableOutput("data_table")
          )
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Load and process data
  health_data <- reactive({
    # Simulate loading Uganda health data
    # In production, this would read the actual CSV files
    data.frame(
      year = rep(2010:2023, each = 4),
      indicator = rep(c("Under-5 Mortality", "Stunting", "Wasting", "Immunization"), 14),
      value = c(
        # Under-5 Mortality (decreasing trend)
        90, 85, 82, 78, 75, 71, 68, 65, 61, 58, 54, 50, 46, 43,
        # Stunting (decreasing trend)
        38, 36, 35, 33, 32, 30, 29, 28, 27, 26, 25, 24, 23, 22,
        # Wasting (fluctuating)
        6, 5.5, 5.8, 5.2, 5.5, 5.1, 4.9, 5.2, 4.8, 4.6, 4.5, 4.3, 4.2, 4.0,
        # Immunization (increasing)
        52, 55, 58, 62, 65, 68, 71, 73, 75, 77, 79, 81, 83, 85
      ),
      region = sample(c("Central", "Eastern", "Northern", "Western"), 56, replace = TRUE)
    )
  })
  
  # Value Boxes
  output$mortality_box <- renderValueBox({
    latest_mortality <- health_data() %>%
      filter(indicator == "Under-5 Mortality", year == max(year)) %>%
      summarise(avg = mean(value)) %>%
      pull(avg)
    
    valueBox(
      value = round(latest_mortality, 1),
      subtitle = "Under-5 Mortality Rate (per 1,000)",
      icon = icon("child"),
      color = "red"
    )
  })
  
  output$malnutrition_box <- renderValueBox({
    latest_stunting <- health_data() %>%
      filter(indicator == "Stunting", year == max(year)) %>%
      summarise(avg = mean(value)) %>%
      pull(avg)
    
    valueBox(
      value = paste0(round(latest_stunting, 1), "%"),
      subtitle = "Stunting Prevalence",
      icon = icon("utensils"),
      color = "yellow"
    )
  })
  
  output$immunization_box <- renderValueBox({
    latest_immun <- health_data() %>%
      filter(indicator == "Immunization", year == max(year)) %>%
      summarise(avg = mean(value)) %>%
      pull(avg)
    
    valueBox(
      value = paste0(round(latest_immun, 1), "%"),
      subtitle = "Immunization Coverage",
      icon = icon("syringe"),
      color = "green"
    )
  })
  
  # Call modules
  dataModule <- callModule(dataModule, "main_data", health_data)
  callModule(visualizationModule, "insights", health_data)
  callModule(analysisModule, "health_analysis", health_data)
  callModule(modelingModule, "predictive_models", health_data)
  
  # Regional Health Map
  output$health_map <- renderLeaflet({
    # Uganda regions approximate coordinates
    regions_data <- data.frame(
      region = c("Central", "Eastern", "Northern", "Western"),
      lat = c(0.3163, 1.0734, 2.8769, 0.6635),
      lng = c(32.5822, 34.1777, 32.2903, 30.2731),
      mortality = c(38, 45, 52, 41),
      color = c("green", "yellow", "red", "yellow")
    )
    
    leaflet(regions_data) %>%
      addTiles() %>%
      setView(lng = 32.2903, lat = 1.3733, zoom = 7) %>%
      addCircleMarkers(
        ~lng, ~lat,
        radius = ~mortality/3,
        color = ~color,
        fillOpacity = 0.7,
        popup = ~paste("<b>", region, "</b><br>",
                      "Under-5 Mortality:", mortality, "per 1,000")
      )
  })
  
  # PSM Analysis
  output$psm_results <- renderPlot({
    req(input$run_psm)
    
    # Simulate PSM results
    set.seed(123)
    n <- 1000
    data <- data.frame(
      treated = rbinom(n, 1, 0.5),
      age = rnorm(n, 3, 1),
      region = sample(1:4, n, replace = TRUE),
      outcome = rnorm(n, 50, 10)
    )
    
    # Add treatment effect
    data$outcome[data$treated == 1] <- data$outcome[data$treated == 1] - 5
    
    # Create plot
    ggplot(data, aes(x = factor(treated), y = outcome, fill = factor(treated))) +
      geom_boxplot(alpha = 0.7) +
      geom_jitter(width = 0.2, alpha = 0.3) +
      scale_fill_manual(values = c("#3498db", "#e74c3c"),
                       labels = c("Control", "Treatment")) +
      labs(title = "Treatment Effect Analysis",
           x = "Group", y = "Outcome",
           fill = "Group") +
      theme_minimal() +
      theme(legend.position = "none")
  })
  
  # Intervention Simulator
  output$intervention_impact <- renderPlotly({
    req(input$simulate)
    
    # Simulate intervention impact
    years <- 0:10
    baseline <- 43
    reduction_rate <- (input$int_coverage * input$int_budget) / 1000
    
    projected <- baseline * exp(-reduction_rate * years / 10)
    
    plot_ly() %>%
      add_trace(x = years, y = rep(baseline, length(years)),
                name = "Without Intervention",
                type = 'scatter', mode = 'lines',
                line = list(dash = 'dash', color = 'red')) %>%
      add_trace(x = years, y = projected,
                name = "With Intervention",
                type = 'scatter', mode = 'lines',
                line = list(color = 'green')) %>%
      layout(title = "Projected Impact on Child Mortality",
             xaxis = list(title = "Years"),
             yaxis = list(title = "Under-5 Mortality Rate"))
  })
  
  output$impact_summary <- renderPrint({
    req(input$simulate)
    
    lives_saved <- round((input$int_coverage / 100) * 3000000 * 0.043 * 
                        (input$int_budget / 10), 0)
    cost_per_life <- round(input$int_budget * 1000000 / lives_saved, 2)
    
    cat("INTERVENTION IMPACT SUMMARY\n")
    cat("===========================\n\n")
    cat("Estimated lives saved over 10 years:", format(lives_saved, big.mark = ","), "\n")
    cat("Cost per life saved: $", format(cost_per_life, big.mark = ","), "\n")
    cat("Population reached:", input$int_coverage, "%\n")
    cat("Total investment: $", input$int_budget, "million\n")
  })
  
  # Data Table
  output$data_table <- DT::renderDataTable({
    DT::datatable(
      health_data(),
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        searchHighlight = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel', 'pdf')
      ),
      extensions = 'Buttons',
      filter = 'top',
      class = 'stripe hover'
    )
  })
  
  # Animate counter on load
  observe({
    invalidateLater(100, session)
    js$animateCounter(id = "mortality-stat", value = 43, duration = 2000)
  })
}

# Run the application
shinyApp(ui = ui, server = server)
