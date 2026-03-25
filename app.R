# app.R - Uganda Child Health Analytics Dashboard
# Main application entry point

# Install packages if needed
if (!requireNamespace("shiny", quietly = TRUE)) {
  source("setup.R")
}

# Load global configuration
source("global.R")

# Source modules
source("modules/dataModule.R")
source("modules/analysisModule.R")
source("modules/modelingModule.R")
source("modules/visualizationModule.R")

# UI Definition
ui <- dashboardPage(
  skin = "blue",

  # Header
  dashboardHeader(
    title = tags$span(
      icon("heartbeat"),
      "Uganda Health Analytics"
    ),
    titleWidth = 300
  ),

  # Sidebar
  dashboardSidebar(
    width = 250,
    sidebarMenu(
      id = "tabs",
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Data Explorer", tabName = "data", icon = icon("database")),
      menuItem("Trends & Patterns", tabName = "analysis", icon = icon("chart-bar")),
      menuItem("Predictions", tabName = "modeling", icon = icon("chart-line")),
      menuItem("Insights", tabName = "visualization", icon = icon("lightbulb"))
    ),
    tags$div(
      style = "padding: 15px; position: absolute; bottom: 0; width: 100%;",
      tags$p(
        style = "color: #aaa; font-size: 12px; text-align: center;",
        "Uganda Child Health Analytics",
        tags$br(),
        "Data Source: WHO/GHO"
      )
    )
  ),

  # Body
  dashboardBody(
    # Include custom CSS and JS
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "custom.css"),
      tags$script(src = "custom.js")
    ),

    useShinyjs(),

    tabItems(
      # Dashboard Overview Tab
      tabItem(tabName = "dashboard",
        fluidRow(
          valueBoxOutput("total_indicators", width = 3),
          valueBoxOutput("datasets_loaded", width = 3),
          valueBoxOutput("years_covered", width = 3),
          valueBoxOutput("data_points", width = 3)
        ),
        fluidRow(
          box(
            title = "Welcome to Uganda Health Analytics",
            width = 8,
            status = "primary",
            solidHeader = TRUE,
            tags$div(
              class = "glass-card",
              h4("About This Dashboard"),
              p("This dashboard helps you explore and understand child health
                trends in Uganda using data from the World Health Organization (WHO).
                No statistics background needed -- just explore!"),
              tags$ul(
                tags$li(tags$strong("Data Explorer:"), " Browse the raw health data with search and filters"),
                tags$li(tags$strong("Trends & Patterns:"), " See how health indicators relate to each other and change over time"),
                tags$li(tags$strong("Predictions:"), " Use models to estimate how changes in water, sanitation, or immunization could affect child health"),
                tags$li(tags$strong("Insights:"), " Key findings and recommended actions at a glance")
              )
            )
          ),
          box(
            title = "Quick Insights",
            width = 4,
            status = "info",
            solidHeader = TRUE,
            visualizationModuleUI("viz_sidebar")
          )
        )
      ),

      # Data Explorer Tab
      tabItem(tabName = "data",
        dataModuleUI("data_explorer")
      ),

      # Statistical Analysis Tab
      tabItem(tabName = "analysis",
        analysisModuleUI("stats_analysis")
      ),

      # ML Modeling Tab
      tabItem(tabName = "modeling",
        modelingModuleUI("ml_modeling")
      ),

      # Visualization / Insights Tab
      tabItem(tabName = "visualization",
        fluidRow(
          box(
            title = "Health Factors & Recommendations",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            visualizationModuleUI("viz_main")
          )
        )
      )
    )
  )
)

# Server Definition
server <- function(input, output, session) {

  # Load and combine health data for modules
  health_data <- reactive({
    files <- c(
      "data/child_mortality_indicators_uga.csv",
      "data/nutrition_indicators_uga.csv",
      "data/malaria_indicators_uga.csv"
    )

    all_data <- lapply(files, read_gho_csv)
    all_data <- all_data[!sapply(all_data, is.null)]

    if (length(all_data) > 0) {
      # Keep the key columns that exist in every dataset
      keep_cols <- c("indicator_code", "indicator", "year", "value",
                     "region", "country", "dimension", "display_value",
                     "lower_bound", "upper_bound")
      all_data <- lapply(all_data, function(dt) {
        cols <- intersect(keep_cols, names(dt))
        dt[, ..cols]
      })
      rbindlist(all_data, fill = TRUE)
    } else {
      # Return sample data if no files found
      data.table(
        indicator = rep(c("Under-5 Mortality", "Stunting", "Immunization"), each = 10),
        year = rep(2010:2019, 3),
        value = c(
          seq(80, 50, length.out = 10),
          seq(35, 28, length.out = 10),
          seq(60, 85, length.out = 10)
        ),
        region = "Africa",
        country = "Uganda"
      )
    }
  })

  # Dashboard value boxes
  output$total_indicators <- renderValueBox({
    df <- health_data()
    n <- length(unique(df$indicator))
    valueBox(n, "Health Indicators", icon = icon("stethoscope"), color = "blue")
  })

  output$datasets_loaded <- renderValueBox({
    n <- sum(file.exists(c(
      "data/child_mortality_indicators_uga.csv",
      "data/nutrition_indicators_uga.csv",
      "data/malaria_indicators_uga.csv",
      "data/health_indicators_uga.csv",
      "data/health_systems_indicators_uga.csv"
    )))
    valueBox(n, "Datasets Loaded", icon = icon("database"), color = "aqua")
  })

  output$years_covered <- renderValueBox({
    df <- health_data()
    valid_years <- df$year[!is.na(df$year) & is.finite(df$year)]
    if (length(valid_years) > 0) {
      years <- range(valid_years)
      valueBox(
        paste(years[1], "-", years[2]),
        "Years Covered",
        icon = icon("calendar"),
        color = "teal"
      )
    } else {
      valueBox("N/A", "Years Covered", icon = icon("calendar"), color = "teal")
    }
  })

  output$data_points <- renderValueBox({
    df <- health_data()
    n_valid <- sum(!is.na(df$value))
    valueBox(
      format(n_valid, big.mark = ","),
      "Data Points",
      icon = icon("chart-line"),
      color = "olive"
    )
  })

  # Initialize modules
  callModule(dataModule, "data_explorer", health_data = health_data)
  callModule(analysisModule, "stats_analysis", health_data = health_data)
  callModule(modelingModule, "ml_modeling", health_data = health_data)
  callModule(visualizationModule, "viz_sidebar", health_data = health_data)
  callModule(visualizationModule, "viz_main", health_data = health_data)

  # Monitor session
  monitor_performance(session$token)
}

# Determine port for deployment (Hugging Face uses 7860)
port <- as.integer(Sys.getenv("PORT", "7860"))
host <- Sys.getenv("HOST", "0.0.0.0")

shinyApp(ui, server, options = list(host = host, port = port))
