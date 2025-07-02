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
