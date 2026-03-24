# Uganda Child Health Analytics Dashboard

An interactive R Shiny dashboard that helps public health professionals, researchers, and humanitarian organizations explore and analyze child health indicators in Uganda. The app brings together data from the WHO Global Health Observatory on child mortality, nutrition, malaria, and health systems, and provides built-in statistical modeling and machine learning tools so users can uncover trends, evaluate interventions, and make data-informed decisions without writing code.

## Who is this for?

- **Public health analysts** tracking child mortality, nutrition, and disease trends in Uganda
- **NGO and humanitarian teams** (e.g., World Vision) evaluating the impact of health interventions
- **Researchers and students** exploring relationships between health determinants like water access, sanitation, immunization, and child outcomes
- **Policy makers** looking for evidence-based insights to guide health investment

## Key Features

### Data Exploration
- Browse five WHO/GHO datasets covering child mortality, nutrition, malaria, health systems, and general health indicators
- Filter by year, region, sex, and other dimensions
- Interactive data tables with search, sort, and CSV/Excel export

### Statistical Analysis
- **Correlation analysis** — Pearson or Spearman correlation heatmaps across selected health indicators
- **Generalized Linear Models (GLM)** — fit Gaussian or Poisson models to examine how water access, sanitation, immunization, and health expenditure relate to mortality and stunting, with full summary output and diagnostic plots
- **Time series decomposition** — additive or multiplicative decomposition of indicator trends over time

### Machine Learning & Prediction
- **Random Forest** and **LASSO/Ridge regression** models with configurable hyperparameters
- Model performance metrics (RMSE, R-squared, MAE) displayed as value boxes
- Actual-vs-predicted scatter plots and residual diagnostics
- Feature importance charts
- Side-by-side model comparison table
- Interactive prediction tool — adjust sliders for water access, sanitation, and immunization coverage to get a predicted child mortality or stunting rate

### Visualization & Insights
- Network graph showing relationships between health determinants (nutrition, WASH, immunization, education, healthcare, economic factors) and child mortality
- Contextual recommendations based on current indicator trends
- Leaflet-ready regional mapping
- All charts are interactive (Plotly) with hover tooltips and zoom

### Performance
- Asynchronous data loading with `future`/`promises`
- Disk-based caching via `memoise`/`cachem` for expensive operations
- GPU-accelerated CSS animations with reduced-motion support
- Responsive design for desktop and mobile

## Data

The `data/` folder contains five CSV files downloaded from the [WHO Global Health Observatory (GHO)](https://www.who.int/data/gho) for Uganda:

| File | Contents |
|------|----------|
| `child_mortality_indicators_uga.csv` | Under-5 mortality rate, child deaths by cause, mortality ages 5-9 |
| `nutrition_indicators_uga.csv` | Stunting, wasting, underweight, and overweight prevalence in children under 5 |
| `malaria_indicators_uga.csv` | Malaria incidence, total cases, and related metrics |
| `health_indicators_uga.csv` | General health indicators including diabetes prevalence, health expenditure |
| `health_systems_indicators_uga.csv` | Health facility density, care-seeking patterns |

Each file uses the standard GHO export format with columns for indicator code/name, year, region, country, dimension (sex, education level, etc.), and numeric value with confidence bounds.

## Project Structure

```
uganda-health-analytics/
├── app.R                    # Shiny app entry point
├── global.R                 # Package loading, caching, theme, helper functions
├── setup.R                  # Auto-installs missing packages from CRAN
├── dependencies.R           # Package list and install helper
├── install_packages.R       # Bulk package installer
├── modules/
│   ├── dataModule.R         # Data exploration UI and server
│   ├── analysisModule.R     # Correlation, GLM, time series decomposition
│   ├── visualizationModule.R# Network graph and AI-powered recommendations
│   └── modelingModule.R     # Random Forest, LASSO/Ridge, predictions
├── data/                    # WHO/GHO CSV datasets for Uganda
├── www/
│   ├── custom.css           # World Vision-branded theme with animations
│   └── custom.js            # Particle system, animated counters, lazy loading
├── renv.lock                # Locked package versions for reproducibility
├── renv/                    # renv bootstrap files
├── DESCRIPTION              # App metadata (required by shinyapps.io)
├── monitor.R                # rsconnect usage metrics and log viewer
├── .github/workflows/
│   └── deploy.yml           # GitHub Actions CI/CD to shinyapps.io
├── .devcontainer/
│   └── devcontainer.json    # VS Code / Codespaces dev container config
├── LICENSE                  # MIT License
└── .gitignore
```

## Getting Started

### Prerequisites

- **R** version 4.2.0 or later (and earlier than 4.5.0)
- **RStudio** (recommended) or any R-capable IDE
- An internet connection (for installing packages on first run)

### 1. Clone the repository

```bash
git clone https://github.com/<your-username>/uganda-health-analytics.git
cd uganda-health-analytics
```

### 2. Restore the renv environment

The project uses [renv](https://rstudio.github.io/renv/) to lock package versions. Open the project in RStudio (or start R in the project directory) and run:

```r
# Install renv if you don't already have it
install.packages("renv")

# Restore all packages from the lock file
renv::restore()
```

This will install the exact package versions recorded in `renv.lock`. It may take several minutes the first time.

**Alternative (without renv):** If you prefer to skip renv, you can install packages directly:

```r
source("setup.R")
```

This installs any missing packages from CRAN.

### 3. Run the app locally

```r
shiny::runApp()
```

The dashboard will open in your default web browser.

## Deployment

### Automatic (GitHub Actions)

Every push to `main` triggers the workflow in `.github/workflows/deploy.yml`, which deploys the app to [shinyapps.io](https://www.shinyapps.io/).

To set this up for your own account, add these repository secrets in GitHub:

| Secret | Description |
|--------|-------------|
| `SHINYAPPS_NAME` | Your shinyapps.io account name |
| `SHINYAPPS_TOKEN` | Your shinyapps.io token |
| `SHINYAPPS_SECRET` | Your shinyapps.io secret |

You can find your token and secret at **shinyapps.io > Account > Tokens**.

### Manual

```r
library(rsconnect)

rsconnect::setAccountInfo(
  name   = "your-account-name",
  token  = "your-token",
  secret = "your-secret"
)

rsconnect::deployApp(
  appDir   = ".",
  appName  = "uganda-health-analytics",
  appTitle = "Uganda Child Health Analytics Dashboard",
  forceUpdate = TRUE
)
```

### Recommended shinyapps.io settings

- **Instance size:** Medium (1 GB RAM) or larger
- **Max worker processes:** 3-5
- **Connection timeout:** 900 seconds
- **Idle timeout:** 300 seconds

## Dev Container

A `.devcontainer/devcontainer.json` is included for VS Code Dev Containers or GitHub Codespaces. It uses the `rocker/rstudio` image and automatically installs `renv` and `rsconnect` on creation.

## Technology Stack

| Layer | Libraries |
|-------|-----------|
| Framework | Shiny, shinydashboard, shinyjs, shinycssloaders |
| Visualization | Plotly, ggplot2, Leaflet, visNetwork |
| Data wrangling | dplyr, tidyr, data.table |
| Statistics | glmnet (LASSO/Ridge), MatchIt (propensity score matching) |
| Machine learning | randomForest |
| Performance | memoise, cachem, future, promises |
| Frontend | Custom CSS (World Vision brand), custom JS (particle system, counters) |

## License

[MIT](LICENSE) — Copyright (c) 2025 Raymond Reuel Wayesu
