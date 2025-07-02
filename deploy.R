# Deploy to shinyapps.io
library(rsconnect)

# Set account info (replace with your details)
rsconnect::setAccountInfo(
  name = 'dnfxdz-raymond-wayesu',
  token = 'EEB5B2C2A49CA95C9772D4BEA6CC45FA',
  secret = 'WGZ9x2usdsezOJp3jwUbpjQSJKuHc0m+kETDuDsm'
)

# Deploy the app
rsconnect::deployApp(
  appDir = ".",
  appName = "uganda-health-analytics",
  appTitle = "Uganda Child Health Analytics Dashboard",
  forceUpdate = TRUE
)
