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
  skin = "black",

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
      menuItem("Statistical Analysis", tabName = "analysis", icon = icon("chart-bar")),
      menuItem("ML Modeling", tabName = "modeling", icon = icon("robot")),
      menuItem("Insights", tabName = "visualization", icon = icon("brain"))
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
              p("This interactive dashboard provides comprehensive analytics on child health
                indicators in Uganda, leveraging data from the World Health Organization's
                Global Health Observatory (GHO)."),
              tags$ul(
                tags$li(tags$strong("Data Explorer:"), " Browse and filter WHO/GHO health datasets"),
                tags$li(tags$strong("Statistical Analysis:"), " Correlation analysis, GLM modeling, and time series decomposition"),
                tags$li(tags$strong("ML Modeling:"), " Random Forest, LASSO, Ridge Regression, and Gradient Boosting"),
                tags$li(tags$strong("Insights:"), " AI-powered recommendations and health determinant networks")
              )
            )
          ),
          box(
            title = "Quick Insights",
            width = 4,
            status = "warning",
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
            title = "Health Determinants & AI Insights",
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
    # Try to load and combine available datasets
    files <- c(
      "data/child_mortality_indicators_uga.csv",
      "data/nutrition_indicators_uga.csv",
      "data/malaria_indicators_uga.csv"
    )

    all_data <- lapply(files, function(f) {
      if (file.exists(f)) {
        df <- data.table::fread(f, stringsAsFactors = FALSE)
        # Standardize column names
        if ("IndicatorCode" %in% names(df) && !"indicator" %in% names(df)) {
          names(df)[names(df) == "IndicatorCode"] <- "indicator"
        }
        if ("TimeDim" %in% names(df) && !"year" %in% names(df)) {
          names(df)[names(df) == "TimeDim"] <- "year"
        }
        if ("NumericValue" %in% names(df) && !"value" %in% names(df)) {
          names(df)[names(df) == "NumericValue"] <- "value"
        }
        if ("Dim1" %in% names(df) && !"region" %in% names(df)) {
          names(df)[names(df) == "Dim1"] <- "region"
        }
        # Ensure required columns exist
        for (col in c("indicator", "year", "value", "region")) {
          if (!col %in% names(df)) {
            df[[col]] <- NA
          }
        }
        df[, c("indicator", "year", "value", "region"), with = FALSE]
      } else {
        NULL
      }
    })

    all_data <- all_data[!sapply(all_data, is.null)]

    if (length(all_data) > 0) {
      data.table::rbindlist(all_data, fill = TRUE)
    } else {
      # Return sample data if no files found
      data.table::data.table(
        indicator = rep(c("Under-5 Mortality", "Stunting", "Immunization"), each = 10),
        year = rep(2010:2019, 3),
        value = c(
          seq(80, 50, length.out = 10),
          seq(35, 28, length.out = 10),
          seq(60, 85, length.out = 10)
        ),
        region = "National"
      )
    }
  })

  # Dashboard value boxes
  output$total_indicators <- renderValueBox({
    df <- health_data()
    n <- length(unique(df$indicator))
    valueBox(n, "Health Indicators", icon = icon("stethoscope"), color = "orange")
  })

  output$datasets_loaded <- renderValueBox({
    n <- sum(file.exists(c(
      "data/child_mortality_indicators_uga.csv",
      "data/nutrition_indicators_uga.csv",
      "data/malaria_indicators_uga.csv",
      "data/health_indicators_uga.csv",
      "data/health_systems_indicators_uga.csv"
    )))
    valueBox(n, "Datasets Loaded", icon = icon("database"), color = "blue")
  })

  output$years_covered <- renderValueBox({
    df <- health_data()
    years <- range(df$year, na.rm = TRUE)
    valueBox(
      paste(years[1], "-", years[2]),
      "Years Covered",
      icon = icon("calendar"),
      color = "green"
    )
  })

  output$data_points <- renderValueBox({
    df <- health_data()
    valueBox(
      format(nrow(df), big.mark = ","),
      "Data Points",
      icon = icon("chart-line"),
      color = "yellow"
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
