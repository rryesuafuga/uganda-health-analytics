# modules/modelingModule.R
# Machine learning and predictive modeling module

modelingModuleUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      column(3,
        box(
          title = "Model Configuration",
          width = NULL,
          status = "primary",
          
          selectInput(ns("model_type"), "Model Type:",
                     choices = c("Random Forest" = "rf",
                               "Gradient Boosting" = "gbm",
                               "LASSO Regression" = "lasso",
                               "Ridge Regression" = "ridge")),
          
          selectInput(ns("target_var"), "Target Variable:",
                     choices = c("Child Mortality" = "mortality",
                               "Stunting Rate" = "stunting")),
          
          sliderInput(ns("train_split"), "Training Split (%):",
                     min = 50, max = 90, value = 80, step = 5),
          
          conditionalPanel(
            condition = "input.model_type == 'rf'",
            ns = ns,
            sliderInput(ns("n_trees"), "Number of Trees:",
                       min = 100, max = 1000, value = 500, step = 100)
          ),
          
          conditionalPanel(
            condition = "input.model_type == 'lasso' || input.model_type == 'ridge'",
            ns = ns,
            sliderInput(ns("lambda"), "Lambda (log scale):",
                       min = -3, max = 3, value = 0, step = 0.1)
          ),
          
          actionButton(ns("train_model"), "Train Model",
                      class = "btn-custom btn-block",
                      icon = icon("robot"))
        )
      ),
      
      column(9,
        tabsetPanel(
          tabPanel("Model Performance",
            br(),
            fluidRow(
              valueBoxOutput(ns("rmse_box")),
              valueBoxOutput(ns("r2_box")),
              valueBoxOutput(ns("mae_box"))
            ),
            fluidRow(
              box(
                title = "Actual vs Predicted",
                width = 6,
                withSpinner(plotlyOutput(ns("pred_plot"), height = "350px"))
              ),
              box(
                title = "Residual Analysis",
                width = 6,
                withSpinner(plotOutput(ns("residual_plot"), height = "350px"))
              )
            )
          ),
          
          tabPanel("Feature Importance",
            br(),
            withSpinner(plotlyOutput(ns("importance_plot"), height = "500px"))
          ),
          
          tabPanel("Model Comparison",
            br(),
            DT::dataTableOutput(ns("model_comparison")),
            br(),
            plotlyOutput(ns("comparison_chart"), height = "400px")
          ),
          
          tabPanel("Predictions",
            br(),
            fluidRow(
              column(6,
                h4("Make Predictions"),
                sliderInput(ns("pred_water"), "Water Access (%):",
                           min = 0, max = 100, value = 70),
                sliderInput(ns("pred_sanitation"), "Sanitation Coverage (%):",
                           min = 0, max = 100, value = 60),
                sliderInput(ns("pred_immunization"), "Immunization Rate (%):",
                           min = 0, max = 100, value = 80),
                actionButton(ns("predict"), "Predict", class = "btn-custom")
              ),
              column(6,
                h4("Prediction Results"),
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
        # Random Forest
        model <- randomForest(
          target ~ .,
          data = train_set,
          ntree = input$n_trees,
          importance = TRUE
        )
      } else if (input$model_type == "lasso" || input$model_type == "ridge") {
        # LASSO/Ridge
        x <- as.matrix(train_set[, -which(names(train_set) == "target")])
        y <- train_set$target
        
        alpha <- ifelse(input$model_type == "lasso", 1, 0)
        lambda <- 10^input$lambda
        
        model <- glmnet(x, y, alpha = alpha, lambda = lambda)
      } else {
        # Placeholder for GBM
        model <- lm(target ~ ., data = train_set)
      }
      
      # Evaluate model
      incProgress(0.8, detail = "Evaluating model...")
      
      # Make predictions
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
        rmse = rmse,
        mae = mae,
        r2 = r2,
        train_actual = train_set$target,
        train_pred = train_pred,
        test_actual = test_set$target,
        test_pred = test_pred,
        train_data = train_set,
        test_data = test_set
      )
      
      # Store in model history
      model_name <- paste(input$model_type, Sys.time())
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
                    "N/A",
                    round(trained_models$performance$rmse, 2)),
      subtitle = "RMSE",
      icon = icon("square-root-alt"),
      color = "red"
    )
  })
  
  output$r2_box <- renderValueBox({
    valueBox(
      value = ifelse(is.null(trained_models$performance),
                    "N/A",
                    paste0(round(trained_models$performance$r2 * 100, 1), "%")),
      subtitle = "R-squared",
      icon = icon("chart-line"),
      color = "green"
    )
  })
  
  output$mae_box <- renderValueBox({
    valueBox(
      value = ifelse(is.null(trained_models$performance),
                    "N/A",
                    round(trained_models$performance$mae, 2)),
      subtitle = "MAE",
      icon = icon("ruler"),
      color = "yellow"
    )
  })
  
  # Actual vs Predicted plot
  output$pred_plot <- renderPlotly({
    req(trained_models$performance)
    
    perf <- trained_models$performance
    
    plot_ly() %>%
      add_trace(
        x = perf$test_actual,
        y = perf$test_pred,
        type = 'scatter',
        mode = 'markers',
        name = 'Test Data',
        marker = list(color = '#3498db', size = 8, opacity = 0.7)
      ) %>%
      add_trace(
        x = c(min(perf$test_actual), max(perf$test_actual)),
        y = c(min(perf$test_actual), max(perf$test_actual)),
        type = 'scatter',
        mode = 'lines',
        name = 'Perfect Prediction',
        line = list(color = 'red', dash = 'dash')
      ) %>%
      layout(
        title = "Actual vs Predicted Values",
        xaxis = list(title = "Actual"),
        yaxis = list(title = "Predicted"),
        hovermode = 'closest'
      )
  })
  
  # Residual plot
  output$residual_plot <- renderPlot({
    req(trained_models$performance)
    
    perf <- trained_models$performance
    residuals <- perf$test_actual - perf$test_pred
    
    par(mfrow = c(2, 1))
    
    # Residuals vs Fitted
    plot(perf$test_pred, residuals,
         xlab = "Fitted Values", ylab = "Residuals",
         main = "Residuals vs Fitted",
         pch = 19, col = rgb(0, 0, 1, 0.5))
    abline(h = 0, col = "red", lty = 2)
    
    # Q-Q plot
    qqnorm(residuals, main = "Normal Q-Q Plot")
    qqline(residuals, col = "red")
  })
  
  # Feature importance
  output$importance_plot <- renderPlotly({
    req(trained_models$current_model)
    
    if (input$model_type == "rf") {
      # Random Forest importance
      importance_df <- as.data.frame(importance(trained_models$current_model))
      importance_df$variable <- rownames(importance_df)
      importance_df <- importance_df[order(importance_df$`%IncMSE`, decreasing = TRUE), ]
      
      plot_ly(
        x = importance_df$`%IncMSE`,
        y = reorder(importance_df$variable, importance_df$`%IncMSE`),
        type = 'bar',
        orientation = 'h',
        marker = list(color = '#3498db')
      ) %>%
        layout(
          title = "Feature Importance (% Increase in MSE)",
          xaxis = list(title = "Importance"),
          yaxis = list(title = ""),
          margin = list(l = 150)
        )
    } else if (input$model_type %in% c("lasso", "ridge")) {
      # LASSO/Ridge coefficients
      coef_vec <- as.vector(coef(trained_models$current_model))[-1]  # Remove intercept
      var_names <- colnames(trained_models$performance$train_data)
      var_names <- var_names[var_names != "target"]
      
      coef_df <- data.frame(
        variable = var_names,
        coefficient = coef_vec
      )
      coef_df <- coef_df[order(abs(coef_df$coefficient), decreasing = TRUE), ]
      
      plot_ly(
        x = coef_df$coefficient,
        y = reorder(coef_df$variable, abs(coef_df$coefficient)),
        type = 'bar',
        orientation = 'h',
        marker = list(color = ifelse(coef_df$coefficient > 0, '#2ecc71', '#e74c3c'))
      ) %>%
        layout(
          title = "Model Coefficients",
          xaxis = list(title = "Coefficient Value"),
          yaxis = list(title = ""),
          margin = list(l = 150)
        )
    } else {
      plot_ly() %>%
        layout(
          title = "Feature importance not available for this model type",
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
      RMSE = sapply(trained_models$models, function(x) round(x$performance$rmse, 3)),
      MAE = sapply(trained_models$models, function(x) round(x$performance$mae, 3)),
      R2 = sapply(trained_models$models, function(x) round(x$performance$r2, 3)),
      stringsAsFactors = FALSE
    )
    
    DT::datatable(
      comparison_data,
      options = list(
        pageLength = 10,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel')
      ),
      extensions = 'Buttons'
    )
  })
  
  # Prediction interface
  observeEvent(input$predict, {
    req(trained_models$current_model)
    
    # Prepare prediction data
    new_data <- data.frame(
      water_access = input$pred_water,
      sanitation = input$pred_sanitation,
      immunization = input$pred_immunization,
      health_exp = 50,  # Default values
      education = 70,
      gdp_per_capita = 2000
    )
    
    # Make prediction
    if (input$model_type == "rf") {
      prediction <- predict(trained_models$current_model, new_data)
    } else if (input$model_type %in% c("lasso", "ridge")) {
      x_new <- as.matrix(new_data)
      prediction <- predict(trained_models$current_model, x_new)[,1]
    } else {
      prediction <- predict(trained_models$current_model, new_data)
    }
    
    # Display results
    output$prediction_results <- renderUI({
      tagList(
        tags$div(
          class = "alert alert-info",
          h4(icon("chart-line"), "Predicted Value"),
          h2(round(prediction, 1), style = "margin: 10px 0;"),
          p("Based on the input parameters")
        ),
        tags$div(
          class = "alert alert-success",
          p(icon("info-circle"), 
            "This prediction suggests that with the given intervention levels, 
            the expected outcome would be", strong(round(prediction, 1)), 
            "per 1,000 live births.")
        )
      )
    })
  })
}

# Helper function to generate modeling data
generateModelingData <- function(n = 1000, target = "mortality") {
  set.seed(123)
  
  # Generate features
  water_access <- runif(n, 30, 95)
  sanitation <- runif(n, 20, 85)
  immunization <- runif(n, 40, 95)
  health_exp <- rnorm(n, 50, 15)
  education <- runif(n, 40, 90)
  gdp_per_capita <- rlnorm(n, 7.5, 0.5)
  
  # Generate target variable with realistic relationships
  if (target == "mortality") {
    # Under-5 mortality rate
    target_var <- 120 - 0.4 * water_access - 0.3 * sanitation - 
                  0.5 * immunization - 0.1 * health_exp - 
                  0.2 * education - 0.00001 * gdp_per_capita + 
                  rnorm(n, 0, 5)
    target_var <- pmax(5, pmin(150, target_var))  # Realistic bounds
  } else {
    # Stunting rate
    target_var <- 50 - 0.2 * water_access - 0.15 * sanitation - 
                  0.1 * immunization - 0.05 * health_exp - 
                  0.3 * education - 0.00002 * gdp_per_capita + 
                  rnorm(n, 0, 3)
    target_var <- pmax(5, pmin(60, target_var))  # Realistic bounds
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
