# modules/dataModule.R
# Data processing and loading module

dataModuleUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      column(4,
        selectInput(ns("indicator"), "Select Indicator:",
                   choices = c("Under-5 Mortality" = "mortality",
                             "Stunting Prevalence" = "stunting",
                             "Wasting Prevalence" = "wasting",
                             "Immunization Coverage" = "immunization",
                             "Malaria Incidence" = "malaria"))
      ),
      column(4,
        selectInput(ns("year_range"), "Year Range:",
                   choices = c("Last 5 years" = 5,
                             "Last 10 years" = 10,
                             "All years" = 100))
      ),
      column(4,
        actionButton(ns("refresh"), "Refresh Data", 
                    icon = icon("sync"),
                    class = "btn-custom",
                    style = "margin-top: 25px;")
      )
    ),
    
    withSpinner(
      plotlyOutput(ns("trend_plot"), height = "400px"),
      type = 6,
      color = "#FF6200"
    )
  )
}

dataModule <- function(input, output, session, health_data) {
  ns <- session$ns
  
  # Reactive data based on selections
  filtered_data <- reactive({
    req(health_data())
    
    data <- health_data()
    
    # Filter by indicator
    indicator_map <- c(
      "mortality" = "Under-5 Mortality",
      "stunting" = "Stunting",
      "wasting" = "Wasting", 
      "immunization" = "Immunization",
      "malaria" = "Malaria"
    )
    
    if (input$indicator %in% names(indicator_map)) {
      data <- data %>%
        filter(indicator == indicator_map[[input$indicator]])
    }
    
    # Filter by year range
    year_limit <- as.numeric(input$year_range)
    max_year <- max(data$year)
    data <- data %>%
      filter(year >= (max_year - year_limit + 1))
    
    return(data)
  })
  
  # Update plot
  output$trend_plot <- renderPlotly({
    data <- filtered_data()
    
    # Create trend plot with confidence intervals
    trend_data <- data %>%
      group_by(year) %>%
      summarise(
        mean_value = mean(value, na.rm = TRUE),
        lower_ci = mean_value - 1.96 * sd(value, na.rm = TRUE) / sqrt(n()),
        upper_ci = mean_value + 1.96 * sd(value, na.rm = TRUE) / sqrt(n()),
        .groups = 'drop'
      )
    
    # Determine color based on indicator
    color_map <- list(
      "mortality" = "#e74c3c",
      "stunting" = "#f39c12",
      "wasting" = "#9b59b6",
      "immunization" = "#27ae60",
      "malaria" = "#e67e22"
    )
    
    line_color <- color_map[[input$indicator]] %||% "#3498db"
    
    p <- plot_ly(trend_data, x = ~year) %>%
      add_trace(y = ~mean_value, type = 'scatter', mode = 'lines+markers',
                name = 'Average',
                line = list(color = line_color, width = 3),
                marker = list(size = 8)) %>%
      add_ribbons(ymin = ~lower_ci, ymax = ~upper_ci,
                  fillcolor = paste0(line_color, "33"),
                  line = list(color = 'transparent'),
                  name = '95% CI',
                  showlegend = FALSE) %>%
      layout(
        title = list(
          text = paste("Trend Analysis:", unique(data$indicator)),
          font = list(size = 18, family = "Arial, sans-serif")
        ),
        xaxis = list(
          title = "Year",
          gridcolor = 'rgba(0,0,0,0.1)',
          zeroline = FALSE
        ),
        yaxis = list(
          title = "Value",
          gridcolor = 'rgba(0,0,0,0.1)',
          zeroline = FALSE
        ),
        plot_bgcolor = 'rgba(0,0,0,0)',
        paper_bgcolor = 'rgba(0,0,0,0)',
        hovermode = 'x unified',
        margin = list(t = 50, b = 50)
      )
    
    # Add annotations for key insights
    if (nrow(trend_data) > 0) {
      latest_value <- tail(trend_data$mean_value, 1)
      first_value <- head(trend_data$mean_value, 1)
      change_pct <- round((latest_value - first_value) / first_value * 100, 1)
      
      p <- p %>%
        add_annotations(
          x = max(trend_data$year),
          y = latest_value,
          text = paste0(ifelse(change_pct > 0, "+", ""), change_pct, "%"),
          showarrow = TRUE,
          arrowhead = 2,
          arrowcolor = ifelse(change_pct < 0, "green", "red"),
          ax = 40,
          ay = -40
        )
    }
    
    p
  })
  
  # Return processed data for use in other modules
  return(filtered_data)
}

# Performance optimized data loading function
loadHealthData <- function(file_paths) {
  # Use data.table for faster reading of large CSV files
  if (require(data.table)) {
    data_list <- lapply(file_paths, fread, stringsAsFactors = FALSE)
  } else {
    data_list <- lapply(file_paths, read.csv, stringsAsFactors = FALSE)
  }
  
  # Combine all data
  combined_data <- do.call(rbind, data_list)
  
  # Clean and process
  combined_data %>%
    filter(COUNTRY..CODE. == "UGA") %>%
    select(
      indicator = GHO..DISPLAY.,
      year = YEAR..DISPLAY.,
      value = Numeric,
      dimension = DIMENSION..NAME.
    ) %>%
    mutate(
      year = as.numeric(gsub("[^0-9]", "", year)),
      value = as.numeric(value)
    ) %>%
    filter(!is.na(year) & !is.na(value))
}
