# Configure cssbundling-rails to use npm instead of yarn
Rails.application.config.cssbundling = {
  use_yarn: false,
  build_command: "npm run build:css"
}