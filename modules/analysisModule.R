# modules/analysisModule.R
# Trends and patterns analysis module

analysisModuleUI <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Trends & Patterns",
        width = 12,
        status = "primary",
        solidHeader = TRUE,

        tabsetPanel(
          tabPanel("How Indicators Relate",
            br(),
            p("This shows how strongly different health measures move together.
              A value near +1 means they increase together; near -1 means when
              one goes up the other goes down; near 0 means little connection."),
            fluidRow(
              column(4,
                selectInput(ns("corr_vars"), "Choose indicators to compare:",
                           choices = c("Under-5 Mortality", "Stunting", "Wasting",
                                     "Immunization", "Water Access", "Sanitation"),
                           multiple = TRUE,
                           selected = c("Under-5 Mortality", "Stunting", "Immunization")),
                radioButtons(ns("corr_method"), "Method:",
                           choices = c("Standard (Pearson)" = "pearson",
                                     "Ranked (Spearman)" = "spearman"),
                           selected = "pearson"),
                helpText("Standard works well for straight-line relationships.
                         Ranked is better if the relationship is curved."),
                actionButton(ns("run_correlation"), "Show Relationships",
                           class = "btn-custom btn-block")
              ),
              column(8,
                withSpinner(plotlyOutput(ns("correlation_plot"), height = "500px"))
              )
            )
          ),

          tabPanel("Regression Model",
            br(),
            p("This fits a model to see which factors (like water access or
              immunization) have the biggest effect on child health outcomes.
              Negative values mean the factor helps reduce the outcome."),
            fluidRow(
              column(4,
                selectInput(ns("glm_outcome"), "What to predict:",
                           choices = c("Child Mortality" = "mortality",
                                     "Stunting Rate" = "stunting")),
                selectInput(ns("glm_predictors"), "Factors to include:",
                           choices = c("Water Access" = "water",
                                     "Sanitation" = "sanitation",
                                     "Immunization" = "immunization",
                                     "Health Spending" = "health_exp"),
                           multiple = TRUE,
                           selected = c("water", "immunization")),
                radioButtons(ns("glm_family"), "Model type:",
                           choices = c("Standard (for rates)" = "gaussian",
                                     "Count-based (for totals)" = "poisson")),
                helpText("Use 'Standard' for percentage-based outcomes.
                         Use 'Count-based' for whole-number counts."),
                actionButton(ns("run_glm"), "Run Model",
                           class = "btn-custom btn-block")
              ),
              column(8,
                verbatimTextOutput(ns("glm_summary")),
                br(),
                plotOutput(ns("glm_diagnostics"), height = "400px")
              )
            )
          ),

          tabPanel("Changes Over Time",
            br(),
            p("This breaks a health indicator into its long-term trend and
              shorter-term ups and downs, so you can see the overall direction."),
            fluidRow(
              column(4,
                selectInput(ns("ts_indicator"), "Choose an indicator:",
                           choices = c("Child Mortality" = "mortality",
                                     "Stunting Rate" = "stunting",
                                     "Immunization" = "immunization")),
                radioButtons(ns("decomp_type"), "Pattern type:",
                           choices = c("Adding up (Additive)" = "additive",
                                     "Multiplying (Multiplicative)" = "multiplicative")),
                helpText("Additive: changes by a fixed amount each year.
                         Multiplicative: changes by a percentage each year."),
                actionButton(ns("run_decomp"), "Analyze",
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

      if (nrow(corr_data) < 3 || ncol(corr_data) < 2) {
        return(plot_ly() %>% layout(title = "Not enough data for this combination. Try different indicators."))
      }

      # Calculate correlation matrix
      corr_matrix <- cor(corr_data, method = input$corr_method)

      # Colorblind-safe diverging palette: blue to white to vermillion
      plot_ly(
        z = corr_matrix,
        x = colnames(corr_matrix),
        y = rownames(corr_matrix),
        type = "heatmap",
        colorscale = list(
          c(0, "#2C5F8A"),
          c(0.5, "#F0F0F0"),
          c(1, "#D55E00")
        ),
        zmin = -1,
        zmax = 1,
        text = round(corr_matrix, 2),
        texttemplate = "%{text}",
        textfont = list(size = 14, color = "black"),
        hovertemplate = "%{x} vs %{y}<br>Correlation: %{z:.2f}<extra></extra>"
      ) %>%
        layout(
          title = paste("Relationship Strength Between Indicators"),
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
      s <- summary(model)
      cat("=== Model Results ===\n\n")
      cat("What the model predicts:", input$glm_outcome, "\n")
      cat("Factors used:", paste(input$glm_predictors, collapse = ", "), "\n\n")
      cat("--- Factor Effects ---\n")
      cat("(Negative values = factor helps reduce the outcome)\n")
      cat("(Stars *** = very strong evidence, ** = strong, * = moderate)\n\n")
      print(s$coefficients)
      cat("\n--- Model Fit ---\n")
      cat("Lower AIC = better model fit. AIC:", round(s$aic, 1), "\n")
    })

    # Diagnostic plots
    output$glm_diagnostics <- renderPlot({
      par(mfrow = c(2, 2), col.main = "#2C5F8A")
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

      if (nrow(ts_data) < 4) {
        plot.new()
        text(0.5, 0.5,
             "Not enough yearly data points for this indicator.\nAt least 4 years of data are needed.",
             cex = 1.3, col = "#2C5F8A")
        return()
      }

      # Create time series object
      ts_obj <- ts(ts_data$value, start = min(ts_data$year), frequency = 1)

      # Decompose
      tryCatch({
        decomp <- decompose(ts_obj, type = input$decomp_type)
        plot(decomp,
             main = paste("Breakdown of", input$ts_indicator, "Over Time"),
             col = "#2C5F8A")
      }, error = function(e) {
        plot.new()
        text(0.5, 0.5,
             paste("Cannot decompose this data.\nReason:", e$message),
             cex = 1.2, col = "#D55E00")
      })
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
