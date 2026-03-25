# modules/dataModule.R
# Data exploration module for viewing and filtering health datasets

dataModuleUI <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Data Explorer",
        width = 12,
        status = "primary",
        solidHeader = TRUE,

        fluidRow(
          column(4,
            selectInput(ns("dataset"), "Choose a dataset:",
                       choices = c(
                         "Child Mortality" = "data/child_mortality_indicators_uga.csv",
                         "Nutrition" = "data/nutrition_indicators_uga.csv",
                         "Malaria" = "data/malaria_indicators_uga.csv",
                         "General Health" = "data/health_indicators_uga.csv",
                         "Health Systems" = "data/health_systems_indicators_uga.csv"
                       ))
          ),
          column(4,
            uiOutput(ns("indicator_filter"))
          ),
          column(4,
            uiOutput(ns("year_filter"))
          )
        ),

        tabsetPanel(
          tabPanel("Data Table",
            br(),
            withSpinner(DT::dataTableOutput(ns("data_table")))
          ),
          tabPanel("Summary",
            br(),
            verbatimTextOutput(ns("data_summary"))
          ),
          tabPanel("Trends",
            br(),
            withSpinner(plotlyOutput(ns("trend_plot"), height = "500px"))
          )
        )
      )
    )
  )
}

dataModule <- function(input, output, session, health_data) {
  ns <- session$ns

  # Load selected dataset (using the shared helper from global.R)
  selected_data <- reactive({
    req(input$dataset)
    df <- read_gho_csv(input$dataset)
    if (is.null(df)) {
      data.frame(Message = "Dataset not found. Please check that data files are present.")
    } else {
      df
    }
  })

  # Dynamic indicator filter
  output$indicator_filter <- renderUI({
    df <- selected_data()
    if ("indicator" %in% names(df)) {
      choices <- sort(unique(df$indicator))
      choices <- choices[nchar(choices) > 0]
      selectInput(ns("indicator"), "Filter by indicator:",
                 choices = c("All indicators" = "All", choices),
                 selected = "All")
    }
  })

  # Dynamic year filter
  output$year_filter <- renderUI({
    df <- selected_data()
    if ("year" %in% names(df)) {
      years <- sort(unique(df$year[!is.na(df$year)]))
      if (length(years) >= 2) {
        sliderInput(ns("year_range"), "Year range:",
                   min = min(years), max = max(years),
                   value = c(min(years), max(years)),
                   step = 1, sep = "")
      }
    }
  })

  # Filtered data
  filtered_data <- reactive({
    df <- selected_data()

    # Filter by indicator
    if (!is.null(input$indicator) && input$indicator != "All" && "indicator" %in% names(df)) {
      df <- df[df$indicator == input$indicator, ]
    }

    # Filter by year range
    if (!is.null(input$year_range) && "year" %in% names(df)) {
      df <- df[!is.na(df$year) & df$year >= input$year_range[1] & df$year <= input$year_range[2], ]
    }

    df
  })

  # Data table output -- show only the most useful columns
  output$data_table <- DT::renderDataTable({
    df <- filtered_data()

    # Select only human-readable columns (drop codes, URLs)
    display_cols <- intersect(
      c("indicator", "year", "value", "display_value",
        "lower_bound", "upper_bound", "region", "country", "dimension"),
      names(df)
    )
    if (length(display_cols) > 0) {
      df <- df[, ..display_cols]
    }

    # Friendly column names for display
    pretty <- c(
      indicator     = "Indicator",
      year          = "Year",
      value         = "Value",
      display_value = "Reported Value",
      lower_bound   = "Lower Bound",
      upper_bound   = "Upper Bound",
      region        = "Region",
      country       = "Country",
      dimension     = "Group"
    )
    for (i in seq_along(names(df))) {
      nm <- names(df)[i]
      if (nm %in% names(pretty)) names(df)[i] <- pretty[[nm]]
    }

    DT::datatable(
      df,
      options = list(
        pageLength = 15,
        scrollX = TRUE,
        dom = 'frtip'
      ),
      filter = 'top',
      rownames = FALSE
    )
  })

  # Summary statistics
  output$data_summary <- renderPrint({
    df <- filtered_data()
    cat("Rows:", nrow(df), "  Columns:", ncol(df), "\n\n")

    if ("indicator" %in% names(df)) {
      cat("Indicators in this dataset:\n")
      indicators <- sort(unique(df$indicator))
      for (ind in indicators) cat("  -", ind, "\n")
      cat("\n")
    }

    if ("year" %in% names(df)) {
      yrs <- df$year[!is.na(df$year)]
      if (length(yrs) > 0) {
        cat("Year range:", min(yrs), "to", max(yrs), "\n\n")
      }
    }

    if ("value" %in% names(df)) {
      vals <- df$value[!is.na(df$value)]
      if (length(vals) > 0) {
        cat("Value summary:\n")
        cat("  Minimum:", round(min(vals), 2), "\n")
        cat("  Median: ", round(median(vals), 2), "\n")
        cat("  Mean:   ", round(mean(vals), 2), "\n")
        cat("  Maximum:", round(max(vals), 2), "\n")
        cat("  Non-missing values:", length(vals), "\n")
      }
    }
  })

  # Trend plot
  output$trend_plot <- renderPlotly({
    df <- filtered_data()

    if (!all(c("year", "value") %in% names(df))) {
      return(
        plot_ly() %>%
          layout(
            title = "No time series data available for this dataset",
            xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
            yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE)
          )
      )
    }

    plot_df <- df[!is.na(df$year) & !is.na(df$value), ]
    if (nrow(plot_df) == 0) {
      return(
        plot_ly() %>%
          layout(title = "No data to plot")
      )
    }

    # Colorblind-safe palette
    cb_palette <- c("#2C5F8A", "#E69F00", "#009E73", "#D55E00",
                    "#56B4E9", "#CC79A7", "#333333", "#0072B2")

    if ("indicator" %in% names(plot_df)) {
      # Limit to top 5 indicators by data count
      top_ind <- names(sort(table(plot_df$indicator), decreasing = TRUE))
      top_ind <- head(top_ind, 5)
      plot_df <- plot_df[plot_df$indicator %in% top_ind, ]

      agg <- aggregate(value ~ year + indicator, data = plot_df, FUN = mean, na.rm = TRUE)

      p <- plot_ly(agg, x = ~year, y = ~value, color = ~indicator,
                  colors = cb_palette,
                  type = 'scatter', mode = 'lines+markers') %>%
        layout(
          title = "Health Indicator Trends Over Time",
          xaxis = list(title = "Year"),
          yaxis = list(title = "Value"),
          hovermode = 'x unified'
        )
    } else {
      agg <- aggregate(value ~ year, data = plot_df, FUN = mean, na.rm = TRUE)

      p <- plot_ly(agg, x = ~year, y = ~value,
                  type = 'scatter', mode = 'lines+markers',
                  line = list(color = '#2C5F8A'),
                  marker = list(color = '#2C5F8A')) %>%
        layout(
          title = "Trend Over Time",
          xaxis = list(title = "Year"),
          yaxis = list(title = "Value")
        )
    }

    p
  })
}
