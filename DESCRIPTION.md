# Deployment Configuration Files for Shinyapps.io

## 1. .gitignore
```
.Rproj.user
.Rhistory
.RData
.Ruserdata
*.Rproj
cache/
rsconnect/
.DS_Store
```

## 2. DESCRIPTION
```
Title: Uganda Child Health Analytics Dashboard
Author: World Vision Analytics Team
AuthorUrl: https://worldvision.org
License: MIT
DisplayMode: Showcase
Tags: health-analytics, uganda, child-mortality, machine-learning
Type: Shiny
```

## 3. dependencies.R
```r
# Install required packages
packages <- c(
  "shiny",
  "shinydashboard", 
  "shinyjs",
  "shinycssloaders",
  "plotly",
  "dplyr",
  "tidyr",
  "ggplot2",
  "DT",
  "glmnet",
  "MatchIt",
  "randomForest",
  "leaflet",
  "visNetwork",
  "data.table",
  "memoise",
  "future",
  "promises",
  "cachem"
)

# Install packages not already installed
install_if_missing <- function(pkg) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
  }
}

lapply(packages, install_if_missing)
```

## 4. rsconnect deployment script (deploy.R)
```r
# Deploy to shinyapps.io
library(rsconnect)

# Set account info (replace with your details)
rsconnect::setAccountInfo(
  name = 'your-account-name',
  token = 'your-token',
  secret = 'your-secret'
)

# Deploy the app
rsconnect::deployApp(
  appDir = ".",
  appName = "uganda-health-analytics",
  appTitle = "Uganda Child Health Analytics Dashboard",
  forceUpdate = TRUE
)
```

## 5. Project Structure
```
uganda-health-analytics/
├── app.R                 # Main application file
├── global.R             # Global configuration
├── modules/             # Shiny modules
│   ├── dataModule.R
│   ├── analysisModule.R
│   ├── visualizationModule.R
│   └── modelingModule.R
├── data/                # Data files (CSV)
│   ├── child_mortality_indicators_uga.csv
│   ├── nutrition_indicators_uga.csv
│   ├── health_indicators_uga.csv
│   ├── malaria_indicators_uga.csv
│   └── health_systems_indicators_uga.csv
├── www/                 # Static assets
│   ├── custom.css      # Additional CSS
│   └── custom.js       # Additional JavaScript
├── cache/              # Cache directory (gitignored)
├── .gitignore
├── DESCRIPTION
├── dependencies.R
└── README.md
```

## 6. README.md
```markdown
# Uganda Child Health Analytics Dashboard

A comprehensive R Shiny dashboard for analyzing child health indicators in Uganda, focusing on World Vision's mission to improve child health outcomes.

## Features

- **Real-time Health Monitoring**: Track key indicators including child mortality, malnutrition, and disease burden
- **Advanced Statistical Analysis**: GLM, LASSO/Ridge regression, and time series decomposition
- **Machine Learning Models**: Random Forest and gradient boosting for predictive analytics
- **Causal Inference**: Propensity score matching for intervention evaluation
- **Interactive Visualizations**: Network analysis, regional maps, and dynamic charts
- **Performance Optimized**: Asynchronous data loading, caching, and efficient rendering

## Technology Stack

- **Framework**: R Shiny with modular architecture
- **UI**: Shinydashboard with custom CSS animations
- **Visualization**: Plotly, Leaflet, visNetwork, ggplot2
- **ML/Statistics**: glmnet, randomForest, MatchIt
- **Performance**: memoise caching, future/promises for async operations
- **Deployment**: Shinyapps.io

## Installation

1. Clone the repository
2. Install dependencies: `source("dependencies.R")`
3. Run locally: `shiny::runApp()`
4. Deploy: `source("deploy.R")`

## Data Sources

Uses UNICEF/WHO health indicator data for Uganda covering:
- Child mortality rates
- Nutrition indicators (stunting, wasting)
- Disease burden (malaria, TB)
- Health system metrics
- WASH indicators

## World Vision Focus Areas

- Child Health & Mortality Reduction
- Nutrition and Food Security
- WASH (Water, Sanitation, and Hygiene)
- Health Systems Strengthening
- Disease Prevention and Control

## License

MIT License
```

## 7. Performance Optimization Tips

### CSS Optimization (www/custom.css)
```css
/* Minified and optimized CSS */
/* Use CSS variables for consistency */
/* Implement GPU-accelerated animations */
/* Lazy load non-critical styles */
```

### JavaScript Optimization (www/custom.js)
```javascript
// Use debouncing for search inputs
function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

// Optimize Shiny input updates
$(document).on('shiny:connected', function() {
  // Debounce search inputs
  $('.search-input').on('input', debounce(function() {
    Shiny.setInputValue('search', this.value);
  }, 300));
});

// Lazy load heavy components
const lazyLoadComponents = () => {
  const options = {
    root: null,
    rootMargin: '0px',
    threshold: 0.1
  };
  
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        // Load component
        Shiny.setInputValue('load_component', entry.target.id);
        observer.unobserve(entry.target);
      }
    });
  }, options);
  
  document.querySelectorAll('.lazy-load').forEach(el => {
    observer.observe(el);
  });
};
```

## 8. Deployment Checklist

- [ ] Test all features locally
- [ ] Optimize data files (remove unnecessary columns)
- [ ] Minify CSS and JavaScript
- [ ] Set appropriate shiny options in global.R
- [ ] Configure caching strategy
- [ ] Test with different screen sizes
- [ ] Check memory usage
- [ ] Deploy to shinyapps.io
- [ ] Monitor performance metrics
- [ ] Set up error logging

## 9. Shinyapps.io Configuration

For optimal performance on shinyapps.io:

1. **Instance Size**: Use at least "Medium" (1GB RAM) for this app
2. **Max Worker Processes**: Set to 3-5
3. **Connection Timeout**: 900 seconds
4. **Idle Timeout**: 300 seconds
5. **Enable Application Logs**: For debugging

## 10. Monitoring Script (monitor.R)
```r
# Monitor app performance
library(rsconnect)

# Get usage metrics
rsconnect::showMetrics(
  appName = "uganda-health-analytics",
  account = "your-account-name"
)

# Show logs
rsconnect::showLogs(
  appName = "uganda-health-analytics",
  account = "your-account-name",
  entries = 100
)
```
