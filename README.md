---
title: Uganda Health Analytics
emoji: 🏥
colorFrom: yellow
colorTo: blue
sdk: docker
pinned: false
---

# Uganda Child Health Analytics Dashboard

This is an interactive web dashboard for exploring child health data in Uganda. It pulls together real data from the World Health Organization on topics like child mortality, nutrition, malaria, and healthcare access, and lets you browse, visualize, and analyze it -- all from your browser, no coding required.

Whether you work in public health, research, policy, or humanitarian aid, this tool gives you a single place to see how Uganda's child health indicators have changed over time and what factors matter most.

**Try it now:** [https://huggingface.co/spaces/ryesuafuga/uganda-health-analytics](https://huggingface.co/spaces/ryesuafuga/uganda-health-analytics) -- no login or install needed, just open the link.

## What can you do with it?

### Browse the data
Pick any of the five WHO datasets and explore them in a searchable, filterable table. You can sort by year, indicator, or group (sex, region, etc.) and see a quick summary of what the data contains.

### See trends and patterns
- **How indicators relate:** Compare indicators like mortality, stunting, and immunization to see which ones move together and which move in opposite directions.
- **Regression model:** Check which factors (water access, sanitation, immunization, health spending) have the biggest effect on child mortality or stunting. The dashboard explains results in plain language.
- **Changes over time:** Break an indicator into its long-term trend and shorter-term fluctuations to spot the overall direction.

### Make predictions
Train a prediction model (Random Forest, LASSO, Ridge, or a simple linear model), then use "What-If Scenarios" to adjust sliders for water access, sanitation, and immunization and see the predicted impact on child mortality or stunting.

### Get insights at a glance
A network diagram shows how major factors (nutrition, water and sanitation, vaccination, education, healthcare access, and economic conditions) connect to child mortality. Below it, the dashboard highlights key findings and recommended actions drawn from the data.

## Data

All data comes from the [WHO Global Health Observatory (GHO)](https://www.who.int/data/gho) and is stored in the `data/` folder as CSV files:

| File | What it covers |
|------|----------------|
| `child_mortality_indicators_uga.csv` | Under-5 mortality rate, child deaths by cause, infant and neonatal deaths |
| `nutrition_indicators_uga.csv` | Stunting, wasting, underweight, and overweight rates in children under 5 |
| `malaria_indicators_uga.csv` | Malaria incidence, confirmed cases, mortality, and treatment metrics |
| `health_indicators_uga.csv` | General health indicators (diabetes, obesity, breastfeeding, air pollution) |
| `health_systems_indicators_uga.csv` | Health facility density, care-seeking patterns |

Each file follows the standard GHO export format with columns for the indicator name, year, region, country, demographic group, and numeric value (plus confidence bounds where available).

## Accessibility

The dashboard uses a **colorblind-safe color palette** (based on the Okabe-Ito scheme) so that all charts and indicators are distinguishable for users with any type of color vision. It also supports reduced-motion preferences and high-contrast mode.

## Project layout

```
uganda-health-analytics/
├── app.R                     # App entry point (UI + server)
├── global.R                  # Shared setup: packages, colors, data-loading helpers
├── setup.R                   # Installs missing R packages automatically
├── Dockerfile                # Docker build for Hugging Face Spaces
├── modules/
│   ├── dataModule.R          # "Data Explorer" tab
│   ├── analysisModule.R      # "Trends & Patterns" tab
│   ├── modelingModule.R      # "Predictions" tab
│   └── visualizationModule.R # "Insights" tab and sidebar quick insights
├── data/                     # WHO/GHO CSV files for Uganda
├── www/
│   ├── custom.css            # Colorblind-safe theme and responsive styles
│   └── custom.js             # Animated counters and interactive helpers
├── renv.lock                 # Locked package versions (for reproducibility)
├── .github/workflows/
│   └── deploy.yml            # GitHub Actions CI/CD to shinyapps.io
├── .devcontainer/
│   └── devcontainer.json     # VS Code / GitHub Codespaces dev container
└── LICENSE                   # MIT
```

## Getting started

### What you need

- **R** version 4.2 or later
- **RStudio** (recommended) or any editor that can run R
- An internet connection for the first-time package install

### 1. Clone the repository

```bash
git clone https://github.com/rryesuafuga/uganda-health-analytics.git
cd uganda-health-analytics
```

### 2. Install packages

The fastest way:

```r
source("setup.R")
```

This checks which packages are missing and installs them from CRAN.

**Or**, if you want exact reproducible versions, use [renv](https://rstudio.github.io/renv/):

```r
install.packages("renv")
renv::restore()
```

### 3. Run the dashboard

```r
shiny::runApp()
```

The app will open in your browser. That's it.

## Deploying to Hugging Face Spaces

This project is set up to run on [Hugging Face Spaces](https://huggingface.co/spaces) as a Docker app.

### 1. Create a Space

Go to [huggingface.co/new-space](https://huggingface.co/new-space), choose **Docker** as the SDK, and name it `uganda-health-analytics`.

### 2. Push the code

Add the Hugging Face Space as a git remote and push:

```bash
git remote add hf https://huggingface.co/spaces/<your-username>/uganda-health-analytics
git push hf main
```

The Space will build the Docker image and start the app automatically. The `Dockerfile` installs all R packages from pre-compiled binaries (via Posit Package Manager) so the build is fast and reliable.

### 3. Wait for the build

The first build takes a few minutes. Once it finishes, your dashboard will be live at:

```
https://huggingface.co/spaces/<your-username>/uganda-health-analytics
```

## Deploying to shinyapps.io

### Automatic (GitHub Actions)

Every push to `main` triggers `.github/workflows/deploy.yml`, which deploys to [shinyapps.io](https://www.shinyapps.io/).

Add these secrets to your GitHub repository (**Settings > Secrets > Actions**):

| Secret | Where to find it |
|--------|-----------------|
| `SHINYAPPS_NAME` | Your shinyapps.io account name |
| `SHINYAPPS_TOKEN` | shinyapps.io > Account > Tokens |
| `SHINYAPPS_SECRET` | shinyapps.io > Account > Tokens |

### Manual deploy

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

## Built with

| What | Libraries |
|------|-----------|
| Web framework | Shiny, shinydashboard, shinyjs |
| Charts | Plotly, ggplot2, Leaflet, visNetwork |
| Data handling | dplyr, tidyr, data.table |
| Modeling | randomForest, glmnet (LASSO/Ridge) |
| Performance | memoise, cachem, future, promises |
| Styling | Custom CSS (colorblind-safe), custom JS |

## License

[MIT](LICENSE) -- Copyright (c) 2025 Raymond Reuel Wayesu
