# global.R - Global configuration and optimization

# At the very top of global.R
if (!requireNamespace("shiny", quietly = TRUE)) {
  source("install_packages.R")
}

# Ensure packages are available
if (!require("shiny")) install.packages("shiny")
if (!require("shinydashboard")) install.packages("shinydashboard")

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
  library(cachem)      # For disk caching
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

# ---- Colorblind-safe palette (Okabe-Ito based) ----
# These colors are distinguishable by people with all types of color vision
uganda_colors <- list(
  primary    = "#2C5F8A",   # Dark blue
  secondary  = "#56B4E9",   # Sky blue
  success    = "#009E73",   # Teal green
  warning    = "#E69F00",   # Amber
  danger     = "#D55E00",   # Vermillion
  info       = "#56B4E9",   # Sky blue
  purple     = "#CC79A7",   # Reddish purple
  dark       = "#333333"    # Near-black
)

# Global theme settings
theme_uganda <- theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", color = "#2C5F8A"),
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

# ---- Helper: read and clean a WHO/GHO CSV ----
# Skips the HXL tag row and renames columns to readable names
read_gho_csv <- function(file_path) {
  if (!file.exists(file_path)) return(NULL)

  df <- fread(file_path, stringsAsFactors = FALSE)

  # Remove HXL tag row (values start with #)
  if (nrow(df) > 0 && grepl("^#", df[[1]][1])) {
    df <- df[-1, ]
  }

  # Standardise column names to short readable forms
  name_map <- c(
    "GHO (CODE)"        = "indicator_code",
    "GHO (DISPLAY)"     = "indicator",
    "GHO (URL)"         = "indicator_url",
    "YEAR (DISPLAY)"    = "year",
    "STARTYEAR"         = "start_year",
    "ENDYEAR"           = "end_year",
    "REGION (CODE)"     = "region_code",
    "REGION (DISPLAY)"  = "region",
    "COUNTRY (CODE)"    = "country_code",
    "COUNTRY (DISPLAY)" = "country",
    "DIMENSION (TYPE)"  = "dimension_type",
    "DIMENSION (CODE)"  = "dimension_code",
    "DIMENSION (NAME)"  = "dimension",
    "Numeric"           = "value",
    "Value"             = "display_value",
    "Low"               = "lower_bound",
    "High"              = "upper_bound"
  )

  for (old_name in names(name_map)) {
    idx <- which(names(df) == old_name)
    if (length(idx) == 1) names(df)[idx] <- name_map[[old_name]]
  }

  # Coerce numeric columns
  for (col in c("year", "start_year", "end_year", "value", "lower_bound", "upper_bound")) {
    if (col %in% names(df)) {
      df[[col]] <- suppressWarnings(as.numeric(df[[col]]))
    }
  }

  as.data.table(df)
}

# Helper functions for consistent styling
create_value_box <- function(value, subtitle, icon_name, color) {
  valueBox(
    value = value,
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
