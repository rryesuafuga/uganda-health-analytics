# modules/visualizationModule.R
# Insights and recommendations module

visualizationModuleUI <- function(id) {
  ns <- NS(id)

  tagList(
    tags$div(
      style = "padding: 15px;",
      h4("Key Findings", icon("lightbulb")),
      hr(),

      # Key metrics -- computed from real data
      uiOutput(ns("key_metrics")),

      # Network visualization
      tags$div(
        style = "margin-top: 20px;",
        h5("What Affects Child Health?"),
        p(style = "font-size: 12px; color: #666;",
          "This diagram shows the major factors that influence child mortality.
           Thicker lines mean a stronger connection."),
        visNetworkOutput(ns("network_viz"), height = "300px")
      ),

      # Action recommendations
      tags$div(
        style = "margin-top: 20px;",
        h5("Recommended Actions"),
        uiOutput(ns("recommendations"))
      )
    )
  )
}

visualizationModule <- function(input, output, session, health_data) {
  ns <- session$ns

  # Compute real metrics from the data
  output$key_metrics <- renderUI({
    df <- tryCatch({
      d <- health_data()
      d[!is.na(d$year) & !is.na(d$value), ]
    }, error = function(e) NULL)

    # Defaults
    mortality_change_label <- "N/A"
    mortality_change_color <- "bg-light-blue"
    latest_year_label      <- "N/A"

    if (!is.null(df) && nrow(df) > 0 && "indicator" %in% names(df)) {
      # Try to find under-5 mortality data
      mortality_patterns <- c("Under-five mortality", "under-five mortality",
                              "Under-5 Mortality", "MDG_0000000007")
      mort_rows <- df[grepl(paste(mortality_patterns, collapse = "|"),
                            df$indicator, ignore.case = TRUE), ]

      if (nrow(mort_rows) > 0) {
        # Get earliest and latest values (average per year)
        agg <- aggregate(value ~ year, data = mort_rows, FUN = mean, na.rm = TRUE)
        agg <- agg[order(agg$year), ]
        if (nrow(agg) >= 2) {
          earliest_val <- agg$value[1]
          latest_val   <- agg$value[nrow(agg)]
          if (!is.na(earliest_val) && earliest_val > 0) {
            pct_change <- round((earliest_val - latest_val) / earliest_val * 100, 0)
            if (pct_change > 0) {
              mortality_change_label <- paste0(pct_change, "% decrease")
              mortality_change_color <- "bg-green"
            } else {
              mortality_change_label <- paste0(abs(pct_change), "% increase")
              mortality_change_color <- "bg-red"
            }
          }
          latest_year_label <- paste0("Since ", agg$year[1])
        }
      }
    }

    tags$div(
      class = "row",
      tags$div(
        class = "col-sm-6",
        tags$div(
          class = paste("small-box", mortality_change_color),
          style = "margin-bottom: 10px;",
          tags$div(
            class = "inner",
            tags$h4(mortality_change_label, style = "margin: 0; font-size: 18px;"),
            tags$p("Child Mortality Change", style = "margin: 0; font-size: 12px;")
          ),
          tags$div(class = "icon", icon("arrow-down"))
        )
      ),
      tags$div(
        class = "col-sm-6",
        tags$div(
          class = "small-box bg-light-blue",
          style = "margin-bottom: 10px;",
          tags$div(
            class = "inner",
            tags$h4(latest_year_label, style = "margin: 0; font-size: 18px;"),
            tags$p("Time Period", style = "margin: 0; font-size: 12px;")
          ),
          tags$div(class = "icon", icon("calendar"))
        )
      )
    )
  })

  # Network visualization showing relationships between health indicators
  output$network_viz <- renderVisNetwork({
    # Colorblind-safe node colors (Okabe-Ito)
    nodes <- data.frame(
      id = 1:7,
      label = c("Child\nMortality", "Nutrition", "Water &\nSanitation",
                "Vaccination", "Education", "Healthcare\nAccess", "Economy"),
      group = c("outcome", "factor", "factor", "factor", "factor", "factor", "factor"),
      value = c(30, 25, 20, 25, 15, 20, 15),
      color = c("#D55E00", "#E69F00", "#56B4E9", "#009E73", "#CC79A7", "#0072B2", "#333333"),
      font.color = "white",
      font.size = 14,
      stringsAsFactors = FALSE
    )

    # Create edges showing relationships
    edges <- data.frame(
      from = c(2, 3, 4, 5, 6, 7, 2, 3, 4),
      to = c(1, 1, 1, 1, 1, 1, 3, 6, 5),
      value = c(3, 2.5, 3.5, 2, 2.5, 1.5, 2, 1.5, 1),
      color = list(opacity = 0.6),
      smooth = list(enabled = TRUE, type = "curvedCW"),
      stringsAsFactors = FALSE
    )

    visNetwork(nodes, edges) %>%
      visOptions(
        highlightNearest = list(enabled = TRUE, degree = 1, hover = TRUE),
        nodesIdSelection = TRUE
      ) %>%
      visPhysics(
        stabilization = list(iterations = 100),
        solver = "forceAtlas2Based"
      ) %>%
      visLayout(randomSeed = 123) %>%
      visInteraction(
        navigationButtons = TRUE,
        zoomView = FALSE
      )
  })

  # Generate recommendations based on actual data
  output$recommendations <- renderUI({
    recommendations <- list()

    tryCatch({
      df <- health_data()
      df <- df[!is.na(df$value) & !is.na(df$year), ]

      if (nrow(df) > 0 && "indicator" %in% names(df)) {
        # Check mortality trend
        mort_rows <- df[grepl("mortality|death", df$indicator, ignore.case = TRUE), ]
        if (nrow(mort_rows) > 0) {
          latest_year <- max(mort_rows$year, na.rm = TRUE)
          latest_mort <- mean(mort_rows$value[mort_rows$year == latest_year], na.rm = TRUE)

          if (!is.na(latest_mort) && is.finite(latest_mort) && latest_mort > 50) {
            recommendations <- append(recommendations, list(
              tags$div(
                class = "alert alert-danger",
                icon("exclamation-triangle"),
                " Child mortality rates remain high. Emergency health interventions
                  and increased healthcare access should be prioritized."
              )
            ))
          }
        }

        # Check malaria
        malaria_rows <- df[grepl("malaria", df$indicator, ignore.case = TRUE), ]
        if (nrow(malaria_rows) > 0) {
          recommendations <- append(recommendations, list(
            tags$div(
              class = "alert alert-warning",
              icon("shield-alt"),
              " Malaria remains a major health challenge. Continued investment in
                bed nets, indoor spraying, and rapid testing can save lives."
            )
          ))
        }

        # Check nutrition
        nutrition_rows <- df[grepl("stunting|wasting|underweight|nutrition",
                                   df$indicator, ignore.case = TRUE), ]
        if (nrow(nutrition_rows) > 0) {
          recommendations <- append(recommendations, list(
            tags$div(
              class = "alert alert-info",
              icon("apple-alt"),
              " Nutrition indicators show room for improvement. Integrating nutrition
                programs with water and sanitation efforts can multiply impact."
            )
          ))
        }
      }

      # Always show general recommendation
      recommendations <- append(recommendations, list(
        tags$div(
          class = "alert alert-success",
          icon("check-circle"),
          " Keep expanding vaccination campaigns and clean water access --
            these are the two strongest levers for reducing child mortality."
        )
      ))
    }, error = function(e) {
      recommendations <<- list(
        tags$div(
          class = "alert alert-info",
          icon("info-circle"),
          " Loading data... Recommendations will appear once data is ready."
        )
      )
    })

    tagList(recommendations)
  })
}
