# Monitor app performance
library(rsconnect)

# Get usage metrics
rsconnect::showMetrics(
  appName = "uganda-health-analytics",
  account = "dnfxdz-raymond-wayesu"
)

# Show logs
rsconnect::showLogs(
  appName = "uganda-health-analytics",
  account = "dnfxdz-raymond-wayesu",
  entries = 100
)
