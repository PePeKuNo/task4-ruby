# Configure jsbundling-rails to use npm instead of yarn
Rails.application.config.jsbundling = {
  use_yarn: false,
  build_command: "npm run build"
}