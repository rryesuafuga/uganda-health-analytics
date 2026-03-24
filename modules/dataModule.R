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
            selectInput(ns("dataset"), "Select Dataset:",
                       choices = c(
                         "Child Mortality" = "data/child_mortality_indicators_uga.csv",
                         "Nutrition" = "data/nutrition_indicators_uga.csv",
                         "Malaria" = "data/malaria_indicators_uga.csv",
                         "Health Indicators" = "data/health_indicators_uga.csv",
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
          tabPanel("Summary Statistics",
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

  # Load selected dataset
  selected_data <- reactive({
    req(input$dataset)
    if (file.exists(input$dataset)) {
      data.table::fread(input$dataset, stringsAsFactors = FALSE)
    } else {
      data.frame(Message = "Dataset not found")
    }
  })

  # Dynamic indicator filter
  output$indicator_filter <- renderUI({
    df <- selected_data()
    if ("IndicatorCode" %in% names(df)) {
      choices <- unique(df$IndicatorCode)
    } else if ("indicator" %in% names(df)) {
      choices <- unique(df$indicator)
    } else {
      choices <- NULL
    }

    if (!is.null(choices) && length(choices) > 0) {
      selectInput(ns("indicator"), "Filter by Indicator:",
                 choices = c("All", choices),
                 selected = "All")
    }
  })

  # Dynamic year filter
  output$year_filter <- renderUI({
    df <- selected_data()
    year_col <- intersect(c("TimeDim", "year", "Year"), names(df))
    if (length(year_col) > 0) {
      years <- sort(unique(df[[year_col[1]]]))
      sliderInput(ns("year_range"), "Year Range:",
                 min = min(years, na.rm = TRUE),
                 max = max(years, na.rm = TRUE),
                 value = c(min(years, na.rm = TRUE), max(years, na.rm = TRUE)),
                 step = 1, sep = "")
    }
  })

  # Filtered data
  filtered_data <- reactive({
    df <- selected_data()

    # Filter by indicator
    if (!is.null(input$indicator) && input$indicator != "All") {
      if ("IndicatorCode" %in% names(df)) {
        df <- df[df$IndicatorCode == input$indicator, ]
      } else if ("indicator" %in% names(df)) {
        df <- df[df$indicator == input$indicator, ]
      }
    }

    # Filter by year range
    if (!is.null(input$year_range)) {
      year_col <- intersect(c("TimeDim", "year", "Year"), names(df))
      if (length(year_col) > 0) {
        df <- df[df[[year_col[1]]] >= input$year_range[1] &
                 df[[year_col[1]]] <= input$year_range[2], ]
      }
    }

    df
  })

  # Data table output
  output$data_table <- DT::renderDataTable({
    DT::datatable(
      filtered_data(),
      options = list(
        pageLength = 15,
        scrollX = TRUE,
        dom = 'Bfrtip'
      ),
      filter = 'top',
      rownames = FALSE
    )
  })

  # Summary statistics
  output$data_summary <- renderPrint({
    df <- filtered_data()
    cat("Dataset Dimensions:", nrow(df), "rows x", ncol(df), "columns\n\n")
    str(df)
    cat("\n--- Numeric Summary ---\n")
    numeric_cols <- sapply(df, is.numeric)
    if (any(numeric_cols)) {
      print(summary(df[, numeric_cols, drop = FALSE]))
    }
  })

  # Trend plot
  output$trend_plot <- renderPlotly({
    df <- filtered_data()

    # Find year and value columns
    year_col <- intersect(c("TimeDim", "year", "Year"), names(df))
    value_col <- intersect(c("NumericValue", "value", "Value"), names(df))
    indicator_col <- intersect(c("IndicatorCode", "indicator", "Indicator"), names(df))

    if (length(year_col) > 0 && length(value_col) > 0) {
      plot_df <- df
      names(plot_df)[names(plot_df) == year_col[1]] <- "year"
      names(plot_df)[names(plot_df) == value_col[1]] <- "value"

      plot_df$value <- as.numeric(plot_df$value)
      plot_df <- plot_df[!is.na(plot_df$value), ]

      if (length(indicator_col) > 0) {
        names(plot_df)[names(plot_df) == indicator_col[1]] <- "indicator"
        # Limit to top 5 indicators by count
        top_indicators <- names(sort(table(plot_df$indicator), decreasing = TRUE))[1:min(5, length(unique(plot_df$indicator)))]
        plot_df <- plot_df[plot_df$indicator %in% top_indicators, ]

        agg <- aggregate(value ~ year + indicator, data = plot_df, FUN = mean, na.rm = TRUE)

        p <- plot_ly(agg, x = ~year, y = ~value, color = ~indicator,
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
                    line = list(color = '#FF6200'),
                    marker = list(color = '#FF6200')) %>%
          layout(
            title = "Trend Over Time",
            xaxis = list(title = "Year"),
            yaxis = list(title = "Value")
          )
      }

      p
    } else {
      plot_ly() %>%
        layout(
          title = "No time series data available for this dataset",
          xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
          yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE)
        )
    }
  })
}
