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
