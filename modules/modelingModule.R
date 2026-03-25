# modules/modelingModule.R
# Prediction and modeling module

modelingModuleUI <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      column(3,
        box(
          title = "Model Settings",
          width = NULL,
          status = "primary",

          selectInput(ns("model_type"), "Prediction method:",
                     choices = c("Random Forest (best for complex patterns)" = "rf",
                               "Linear Model (simplest)" = "gbm",
                               "LASSO (selects key factors)" = "lasso",
                               "Ridge (uses all factors)" = "ridge")),

          selectInput(ns("target_var"), "What to predict:",
                     choices = c("Child Mortality Rate" = "mortality",
                               "Stunting Rate" = "stunting")),

          sliderInput(ns("train_split"), "Training data (%):",
                     min = 50, max = 90, value = 80, step = 5),
          helpText("Higher = model learns from more data, but less is left for testing."),

          conditionalPanel(
            condition = "input.model_type == 'rf'",
            ns = ns,
            sliderInput(ns("n_trees"), "Number of decision trees:",
                       min = 100, max = 1000, value = 500, step = 100)
          ),

          conditionalPanel(
            condition = "input.model_type == 'lasso' || input.model_type == 'ridge'",
            ns = ns,
            sliderInput(ns("lambda"), "Regularization strength:",
                       min = -3, max = 3, value = 0, step = 0.1),
            helpText("Higher = simpler model. Lower = more flexible model.")
          ),

          actionButton(ns("train_model"), "Train Model",
                      class = "btn-custom btn-block",
                      icon = icon("play"))
        )
      ),

      column(9,
        tabsetPanel(
          tabPanel("How Good Is the Model?",
            br(),
            p("These numbers tell you how accurate the model's predictions are.
              Lower error = better. Higher accuracy = better."),
            fluidRow(
              valueBoxOutput(ns("rmse_box")),
              valueBoxOutput(ns("r2_box")),
              valueBoxOutput(ns("mae_box"))
            ),
            fluidRow(
              box(
                title = "Predicted vs Actual Values",
                width = 6,
                p(style = "font-size: 12px; color: #666;",
                  "Points close to the dashed line mean the model predicted well."),
                withSpinner(plotlyOutput(ns("pred_plot"), height = "350px"))
              ),
              box(
                title = "Prediction Errors",
                width = 6,
                p(style = "font-size: 12px; color: #666;",
                  "Errors should be randomly scattered around zero (no pattern)."),
                withSpinner(plotOutput(ns("residual_plot"), height = "350px"))
              )
            )
          ),

          tabPanel("Which Factors Matter Most?",
            br(),
            p("This chart shows which factors have the biggest influence
              on the prediction. Longer bars = more important."),
            withSpinner(plotlyOutput(ns("importance_plot"), height = "500px"))
          ),

          tabPanel("Compare Models",
            br(),
            p("Train different models and compare them here.
              Lower error and higher accuracy means a better model."),
            DT::dataTableOutput(ns("model_comparison")),
            br(),
            plotlyOutput(ns("comparison_chart"), height = "400px")
          ),

          tabPanel("What-If Scenarios",
            br(),
            p("Adjust the sliders to see how changes in water, sanitation,
              or immunization could affect child health outcomes."),
            fluidRow(
              column(6,
                h4("Set Scenario Values"),
                sliderInput(ns("pred_water"), "Water Access (%):",
                           min = 0, max = 100, value = 70),
                sliderInput(ns("pred_sanitation"), "Sanitation Coverage (%):",
                           min = 0, max = 100, value = 60),
                sliderInput(ns("pred_immunization"), "Immunization Rate (%):",
                           min = 0, max = 100, value = 80),
                actionButton(ns("predict"), "Calculate Prediction", class = "btn-custom")
              ),
              column(6,
                h4("Predicted Outcome"),
                uiOutput(ns("prediction_results"))
              )
            )
          )
        )
      )
    )
  )
}

modelingModule <- function(input, output, session, health_data) {
  ns <- session$ns

  # Store trained models
  trained_models <- reactiveValues(
    models = list(),
    current_model = NULL,
    performance = NULL
  )

  # Train model
  observeEvent(input$train_model, {
    withProgress(message = 'Training model...', value = 0, {

      # Generate training data
      incProgress(0.2, detail = "Preparing data...")
      train_data <- generateModelingData(n = 1000, target = input$target_var)

      # Split data
      incProgress(0.4, detail = "Splitting data...")
      train_idx <- sample(nrow(train_data), nrow(train_data) * input$train_split / 100)
      train_set <- train_data[train_idx, ]
      test_set <- train_data[-train_idx, ]

      # Train model based on type
      incProgress(0.6, detail = "Training model...")

      if (input$model_type == "rf") {
        model <- randomForest(
          target ~ .,
          data = train_set,
          ntree = input$n_trees,
          importance = TRUE
        )
      } else if (input$model_type == "lasso" || input$model_type == "ridge") {
        x <- as.matrix(train_set[, -which(names(train_set) == "target")])
        y <- train_set$target
        alpha <- ifelse(input$model_type == "lasso", 1, 0)
        lambda <- 10^input$lambda
        model <- glmnet(x, y, alpha = alpha, lambda = lambda)
      } else {
        model <- lm(target ~ ., data = train_set)
      }

      # Evaluate model
      incProgress(0.8, detail = "Evaluating model...")

      if (input$model_type == "rf") {
        train_pred <- predict(model, train_set)
        test_pred <- predict(model, test_set)
      } else if (input$model_type %in% c("lasso", "ridge")) {
        x_train <- as.matrix(train_set[, -which(names(train_set) == "target")])
        x_test <- as.matrix(test_set[, -which(names(test_set) == "target")])
        train_pred <- predict(model, x_train)[,1]
        test_pred <- predict(model, x_test)[,1]
      } else {
        train_pred <- predict(model, train_set)
        test_pred <- predict(model, test_set)
      }

      # Calculate metrics
      rmse <- sqrt(mean((test_set$target - test_pred)^2))
      mae <- mean(abs(test_set$target - test_pred))
      r2 <- cor(test_set$target, test_pred)^2

      # Store results
      trained_models$current_model <- model
      trained_models$performance <- list(
        rmse = rmse, mae = mae, r2 = r2,
        train_actual = train_set$target, train_pred = train_pred,
        test_actual = test_set$target, test_pred = test_pred,
        train_data = train_set, test_data = test_set
      )

      # Store in model history
      model_name <- paste(input$model_type, format(Sys.time(), "%H:%M:%S"))
      trained_models$models[[model_name]] <- list(
        model = model,
        performance = trained_models$performance,
        type = input$model_type
      )

      incProgress(1, detail = "Complete!")
    })
  })

  # Performance metrics boxes
  output$rmse_box <- renderValueBox({
    valueBox(
      value = ifelse(is.null(trained_models$performance),
                    "Train a model first",
                    round(trained_models$performance$rmse, 2)),
      subtitle = "Average Error (RMSE) -- lower is better",
      icon = icon("bullseye"),
      color = "blue"
    )
  })

  output$r2_box <- renderValueBox({
    valueBox(
      value = ifelse(is.null(trained_models$performance),
                    "---",
                    paste0(round(trained_models$performance$r2 * 100, 1), "%")),
      subtitle = "Accuracy (R-squared) -- higher is better",
      icon = icon("chart-line"),
      color = "teal"
    )
  })

  output$mae_box <- renderValueBox({
    valueBox(
      value = ifelse(is.null(trained_models$performance),
                    "---",
                    round(trained_models$performance$mae, 2)),
      subtitle = "Typical Error (MAE) -- lower is better",
      icon = icon("ruler"),
      color = "olive"
    )
  })

  # Actual vs Predicted plot
  output$pred_plot <- renderPlotly({
    req(trained_models$performance)
    perf <- trained_models$performance

    plot_ly() %>%
      add_trace(
        x = perf$test_actual, y = perf$test_pred,
        type = 'scatter', mode = 'markers', name = 'Test Data',
        marker = list(color = '#2C5F8A', size = 8, opacity = 0.7)
      ) %>%
      add_trace(
        x = c(min(perf$test_actual), max(perf$test_actual)),
        y = c(min(perf$test_actual), max(perf$test_actual)),
        type = 'scatter', mode = 'lines', name = 'Perfect Prediction',
        line = list(color = '#D55E00', dash = 'dash')
      ) %>%
      layout(
        title = "Predicted vs Actual",
        xaxis = list(title = "Actual Value"),
        yaxis = list(title = "Model's Prediction"),
        hovermode = 'closest'
      )
  })

  # Residual plot
  output$residual_plot <- renderPlot({
    req(trained_models$performance)
    perf <- trained_models$performance
    residuals <- perf$test_actual - perf$test_pred

    par(mfrow = c(2, 1))
    plot(perf$test_pred, residuals,
         xlab = "Predicted Values", ylab = "Prediction Errors",
         main = "Errors vs Predictions (should be randomly scattered)",
         pch = 19, col = rgb(0.17, 0.37, 0.54, 0.5))
    abline(h = 0, col = "#D55E00", lty = 2, lwd = 2)
    qqnorm(residuals, main = "Error Distribution (should follow the line)",
           pch = 19, col = rgb(0.17, 0.37, 0.54, 0.5))
    qqline(residuals, col = "#D55E00", lwd = 2)
  })

  # Feature importance
  output$importance_plot <- renderPlotly({
    req(trained_models$current_model)

    # Friendly variable names
    pretty_names <- c(
      water_access = "Water Access",
      sanitation = "Sanitation",
      immunization = "Immunization",
      health_exp = "Health Spending",
      education = "Education",
      gdp_per_capita = "GDP per Capita"
    )

    if (input$model_type == "rf") {
      importance_df <- as.data.frame(importance(trained_models$current_model))
      importance_df$variable <- rownames(importance_df)
      importance_df$label <- ifelse(importance_df$variable %in% names(pretty_names),
                                    pretty_names[importance_df$variable],
                                    importance_df$variable)
      importance_df <- importance_df[order(importance_df$`%IncMSE`, decreasing = TRUE), ]

      plot_ly(
        x = importance_df$`%IncMSE`,
        y = reorder(importance_df$label, importance_df$`%IncMSE`),
        type = 'bar', orientation = 'h',
        marker = list(color = '#2C5F8A')
      ) %>%
        layout(
          title = "Factor Importance (higher = more influential)",
          xaxis = list(title = "Importance Score"),
          yaxis = list(title = ""),
          margin = list(l = 150)
        )
    } else if (input$model_type %in% c("lasso", "ridge")) {
      coef_vec <- as.vector(coef(trained_models$current_model))[-1]
      var_names <- colnames(trained_models$performance$train_data)
      var_names <- var_names[var_names != "target"]
      labels <- ifelse(var_names %in% names(pretty_names),
                        pretty_names[var_names], var_names)

      coef_df <- data.frame(
        variable = labels,
        coefficient = coef_vec,
        stringsAsFactors = FALSE
      )
      coef_df <- coef_df[order(abs(coef_df$coefficient), decreasing = TRUE), ]

      plot_ly(
        x = coef_df$coefficient,
        y = reorder(coef_df$variable, abs(coef_df$coefficient)),
        type = 'bar', orientation = 'h',
        marker = list(color = ifelse(coef_df$coefficient > 0, '#D55E00', '#2C5F8A'))
      ) %>%
        layout(
          title = "Factor Effects (blue = helps reduce, orange = increases)",
          xaxis = list(title = "Effect Size"),
          yaxis = list(title = ""),
          margin = list(l = 150)
        )
    } else {
      plot_ly() %>%
        layout(
          title = "Train a Random Forest or LASSO/Ridge model to see factor importance",
          xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
          yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE)
        )
    }
  })

  # Model comparison
  output$model_comparison <- DT::renderDataTable({
    req(length(trained_models$models) > 0)

    comparison_data <- data.frame(
      Model = names(trained_models$models),
      Type = sapply(trained_models$models, function(x) x$type),
      `Average Error` = sapply(trained_models$models, function(x) round(x$performance$rmse, 3)),
      `Typical Error` = sapply(trained_models$models, function(x) round(x$performance$mae, 3)),
      `Accuracy` = sapply(trained_models$models, function(x) paste0(round(x$performance$r2 * 100, 1), "%")),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )

    DT::datatable(
      comparison_data,
      options = list(pageLength = 10, dom = 'frtip'),
      rownames = FALSE
    )
  })

  # Prediction interface
  observeEvent(input$predict, {
    req(trained_models$current_model)

    new_data <- data.frame(
      water_access = input$pred_water,
      sanitation = input$pred_sanitation,
      immunization = input$pred_immunization,
      health_exp = 50,
      education = 70,
      gdp_per_capita = 2000
    )

    prediction <- tryCatch({
      if (input$model_type == "rf") {
        predict(trained_models$current_model, new_data)
      } else if (input$model_type %in% c("lasso", "ridge")) {
        x_new <- as.matrix(new_data)
        predict(trained_models$current_model, x_new)[,1]
      } else {
        predict(trained_models$current_model, new_data)
      }
    }, error = function(e) NA)

    output$prediction_results <- renderUI({
      if (is.na(prediction)) {
        return(tags$div(class = "alert alert-warning",
          "Could not generate prediction. Try retraining the model."))
      }

      target_label <- ifelse(input$target_var == "mortality",
                              "child deaths per 1,000 live births",
                              "% of children stunted")

      tagList(
        tags$div(
          class = "alert alert-info",
          h4(icon("chart-line"), "Predicted Value"),
          h2(round(prediction, 1), style = "margin: 10px 0;"),
          p(target_label)
        ),
        tags$div(
          class = "alert alert-success",
          p(icon("info-circle"),
            "With", strong(paste0(input$pred_water, "%")), "water access,",
            strong(paste0(input$pred_sanitation, "%")), "sanitation, and",
            strong(paste0(input$pred_immunization, "%")), "immunization,",
            "the model estimates", strong(round(prediction, 1)), target_label, ".")
        )
      )
    })
  })
}

# Helper function to generate modeling data
generateModelingData <- function(n = 1000, target = "mortality") {
  set.seed(123)

  water_access <- runif(n, 30, 95)
  sanitation <- runif(n, 20, 85)
  immunization <- runif(n, 40, 95)
  health_exp <- rnorm(n, 50, 15)
  education <- runif(n, 40, 90)
  gdp_per_capita <- rlnorm(n, 7.5, 0.5)

  if (target == "mortality") {
    target_var <- 120 - 0.4 * water_access - 0.3 * sanitation -
                  0.5 * immunization - 0.1 * health_exp -
                  0.2 * education - 0.00001 * gdp_per_capita +
                  rnorm(n, 0, 5)
    target_var <- pmax(5, pmin(150, target_var))
  } else {
    target_var <- 50 - 0.2 * water_access - 0.15 * sanitation -
                  0.1 * immunization - 0.05 * health_exp -
                  0.3 * education - 0.00002 * gdp_per_capita +
                  rnorm(n, 0, 3)
    target_var <- pmax(5, pmin(60, target_var))
  }

  data.frame(
    target = target_var,
    water_access = water_access,
    sanitation = sanitation,
    immunization = immunization,
    health_exp = health_exp,
    education = education,
    gdp_per_capita = gdp_per_capita
  )
}
