# Deploy to shinyapps.io
library(rsconnect)

# Set account info (replace with your details)
rsconnect::setAccountInfo(
  name = 'dnfxdz-raymond-wayesu',
  token = '4726F3D736CB5DD0B66707465523E4A2',
  secret = 'DnIe0F4OyeX27UGTXMyU1B8aEMyXMqUOlr6Pe8l8'
)

# Deploy the app
rsconnect::deployApp(
  appDir = ".",
  appName = "uganda-health-analytics",
  appTitle = "Uganda Child Health Analytics Dashboard",
  forceUpdate = TRUE
)
