# global.R - Global configuration and optimization

# Performance optimization: Load libraries once
suppressPackageStartupMessages({
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
  library(data.table)  # For faster data operations
  library(memoise)     # For caching
  library(future)      # For async operations
  library(promises)    # For async operations
})

# Enable async processing
plan(multisession, workers = 2)

# Global options for performance
options(
  shiny.maxRequestSize = 50*1024^2,  # 50MB max upload
  shiny.usecairo = FALSE,            # Faster rendering
  shiny.sanitize.errors = FALSE,     # Better error messages
  DT.options = list(pageLength = 25, dom = 'Bfrtip')
)

# Cache expensive operations
cached_load_data <- memoise(function(file_path) {
  if (file.exists(file_path)) {
    fread(file_path, stringsAsFactors = FALSE)
  } else {
    NULL
  }
}, cache = cachem::cache_disk("cache"))

# Preload data files if available
data_files <- c(
  "data/child_mortality_indicators_uga.csv",
  "data/nutrition_indicators_uga.csv",
  "data/health_indicators_uga.csv",
  "data/malaria_indicators_uga.csv",
  "data/health_systems_indicators_uga.csv"
)

# Load data asynchronously
future_promise({
  lapply(data_files, function(f) {
    if (file.exists(f)) cached_load_data(f)
  })
})

# Global theme settings
theme_uganda <- theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", color = "#FF6200"),
    plot.subtitle = element_text(size = 12, color = "#666"),
    axis.title = element_text(size = 12),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "transparent"),
    plot.background = element_rect(fill = "transparent", color = NA)
  )

# Set global theme
theme_set(theme_uganda)

# Plotly global config
plotly_config <- list(
  displayModeBar = FALSE,
  responsive = TRUE
)

# Color palette
uganda_colors <- list(
  primary = "#FF6200",
  secondary = "#0095DA",
  success = "#52C41A",
  warning = "#FAAD14",
  danger = "#F5222D",
  info = "#1890FF"
)

# Helper functions for consistent styling
create_value_box <- function(value, subtitle, icon_name, color) {
  valueBox(
    value = tags$span(
      class = "animated-counter",
      "data-end" = gsub("[^0-9.-]", "", as.character(value)),
      value
    ),
    subtitle = subtitle,
    icon = icon(icon_name),
    color = color
  )
}

# Performance monitoring
monitor_performance <- function(session_id) {
  if (getOption("shiny.trace", FALSE)) {
    message(paste("Session started:", session_id, "at", Sys.time()))
  }
}

# Error handling wrapper
safe_plot <- function(plot_function, ...) {
  tryCatch({
    plot_function(...)
  }, error = function(e) {
    plot_ly() %>%
      layout(
        title = "Error generating plot",
        annotations = list(
          text = paste("Error:", e$message),
          showarrow = FALSE,
          xref = "paper",
          yref = "paper",
          x = 0.5,
          y = 0.5
        )
      )
  })
}
