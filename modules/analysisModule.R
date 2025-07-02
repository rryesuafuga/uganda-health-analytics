# modules/analysisModule.R
# Statistical analysis module with GLM and correlation analysis

analysisModuleUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Statistical Analysis Dashboard",
        width = 12,
        status = "primary",
        solidHeader = TRUE,
        
        tabsetPanel(
          tabPanel("Correlation Analysis",
            br(),
            fluidRow(
              column(4,
                selectInput(ns("corr_vars"), "Select Variables:",
                           choices = c("Under-5 Mortality", "Stunting", "Wasting",
                                     "Immunization", "Water Access", "Sanitation"),
                           multiple = TRUE,
                           selected = c("Under-5 Mortality", "Stunting", "Immunization")),
                radioButtons(ns("corr_method"), "Correlation Method:",
                           choices = c("Pearson" = "pearson",
                                     "Spearman" = "spearman")),
                actionButton(ns("run_correlation"), "Run Analysis",
                           class = "btn-custom btn-block")
              ),
              column(8,
                withSpinner(plotlyOutput(ns("correlation_plot"), height = "500px"))
              )
            )
          ),
          
          tabPanel("GLM Analysis",
            br(),
            fluidRow(
              column(4,
                selectInput(ns("glm_outcome"), "Outcome Variable:",
                           choices = c("Under-5 Mortality" = "mortality",
                                     "Stunting" = "stunting")),
                selectInput(ns("glm_predictors"), "Predictor Variables:",
                           choices = c("Water Access" = "water",
                                     "Sanitation" = "sanitation",
                                     "Immunization" = "immunization",
                                     "Health Expenditure" = "health_exp"),
                           multiple = TRUE,
                           selected = c("water", "immunization")),
                radioButtons(ns("glm_family"), "GLM Family:",
                           choices = c("Gaussian" = "gaussian",
                                     "Poisson" = "poisson")),
                actionButton(ns("run_glm"), "Run GLM",
                           class = "btn-custom btn-block")
              ),
              column(8,
                verbatimTextOutput(ns("glm_summary")),
                br(),
                plotOutput(ns("glm_diagnostics"), height = "400px")
              )
            )
          ),
          
          tabPanel("Time Series Decomposition",
            br(),
            fluidRow(
              column(4,
                selectInput(ns("ts_indicator"), "Select Indicator:",
                           choices = c("Under-5 Mortality" = "mortality",
                                     "Stunting" = "stunting",
                                     "Immunization" = "immunization")),
                radioButtons(ns("decomp_type"), "Decomposition Type:",
                           choices = c("Additive" = "additive",
                                     "Multiplicative" = "multiplicative")),
                actionButton(ns("run_decomp"), "Decompose",
                           class = "btn-custom btn-block")
              ),
              column(8,
                withSpinner(plotOutput(ns("ts_decomp_plot"), height = "500px"))
              )
            )
          )
        )
      )
    )
  )
}

analysisModule <- function(input, output, session, health_data) {
  ns <- session$ns
  
  # Correlation Analysis
  observeEvent(input$run_correlation, {
    req(input$corr_vars, length(input$corr_vars) >= 2)
    
    output$correlation_plot <- renderPlotly({
      # Prepare data for correlation
      corr_data <- health_data() %>%
        filter(indicator %in% input$corr_vars) %>%
        select(year, indicator, value, region) %>%
        pivot_wider(names_from = indicator, values_from = value, values_fn = mean) %>%
        select(-year, -region) %>%
        na.omit()
      
      # Calculate correlation matrix
      corr_matrix <- cor(corr_data, method = input$corr_method)
      
      # Create heatmap
      plot_ly(
        z = corr_matrix,
        x = colnames(corr_matrix),
        y = rownames(corr_matrix),
        type = "heatmap",
        colorscale = list(
          c(0, "#3498db"),
          c(0.5, "#ffffff"),
          c(1, "#e74c3c")
        ),
        zmin = -1,
        zmax = 1,
        text = round(corr_matrix, 2),
        texttemplate = "%{text}",
        textfont = list(size = 14, color = "black"),
        hovertemplate = "%{x} vs %{y}<br>Correlation: %{z:.2f}<extra></extra>"
      ) %>%
        layout(
          title = paste("Correlation Matrix -", input$corr_method),
          xaxis = list(title = "", tickangle = -45),
          yaxis = list(title = ""),
          width = 700,
          height = 500
        )
    })
  })
  
  # GLM Analysis
  observeEvent(input$run_glm, {
    req(input$glm_outcome, input$glm_predictors)
    
    # Prepare data for GLM
    glm_data <- generateGLMData(health_data(), input$glm_outcome, input$glm_predictors)
    
    # Fit GLM model
    formula_str <- paste(input$glm_outcome, "~", paste(input$glm_predictors, collapse = " + "))
    
    if (input$glm_family == "gaussian") {
      model <- glm(as.formula(formula_str), data = glm_data, family = gaussian())
    } else {
      model <- glm(as.formula(formula_str), data = glm_data, family = poisson())
    }
    
    # Display summary
    output$glm_summary <- renderPrint({
      summary(model)
    })
    
    # Diagnostic plots
    output$glm_diagnostics <- renderPlot({
      par(mfrow = c(2, 2))
      plot(model)
    })
  })
  
  # Time Series Decomposition
  observeEvent(input$run_decomp, {
    req(input$ts_indicator)
    
    output$ts_decomp_plot <- renderPlot({
      # Get time series data
      ts_data <- health_data() %>%
        filter(indicator == switch(input$ts_indicator,
                                 "mortality" = "Under-5 Mortality",
                                 "stunting" = "Stunting",
                                 "immunization" = "Immunization")) %>%
        group_by(year) %>%
        summarise(value = mean(value, na.rm = TRUE), .groups = 'drop') %>%
        arrange(year)
      
      # Create time series object
      ts_obj <- ts(ts_data$value, start = min(ts_data$year), frequency = 1)
      
      # Decompose
      if (length(ts_obj) >= 2) {
        decomp <- decompose(ts_obj, type = input$decomp_type)
        
        # Plot decomposition
        plot(decomp, main = paste("Time Series Decomposition -", input$ts_indicator))
      } else {
        plot.new()
        text(0.5, 0.5, "Insufficient data for decomposition", cex = 1.5)
      }
    })
  })
}

# Helper function to generate GLM data
generateGLMData <- function(health_data, outcome, predictors) {
  # Simulate realistic relationships between variables
  n <- 200
  set.seed(123)
  
  # Generate predictors
  water <- runif(n, 30, 95)
  sanitation <- runif(n, 20, 85)
  immunization <- runif(n, 40, 95)
  health_exp <- rnorm(n, 50, 15)
  
  # Generate outcome based on predictors
  if (outcome == "mortality") {
    mortality <- 100 - 0.3 * water - 0.2 * sanitation - 0.4 * immunization - 0.1 * health_exp + rnorm(n, 0, 5)
    mortality <- pmax(0, mortality)
  } else {
    stunting <- 60 - 0.2 * water - 0.15 * sanitation - 0.1 * immunization - 0.05 * health_exp + rnorm(n, 0, 3)
    stunting <- pmax(0, pmin(100, stunting))
  }
  
  data.frame(
    mortality = if(outcome == "mortality") mortality else rnorm(n, 45, 10),
    stunting = if(outcome == "stunting") stunting else rnorm(n, 25, 5),
    water = water,
    sanitation = sanitation,
    immunization = immunization,
    health_exp = health_exp
  )
}
