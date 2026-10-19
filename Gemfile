source "https://rubygems.org"

gem "rails", "~> 8.1.4"
gem "propshaft"
# IMPORTANT: SQLite is used for ALL environments (development, test AND production).
# NOTA BENE: The `pg` gem was removed — it broke the Railway build because our
# Gemfile.lock is generated on Windows (x64-mingw-ucrt) and Bundler could not find
# a pg variant valid for both Windows and Linux platforms. SQLite needs no native
# platform-specific gems, so the build is now deterministic on any OS.
gem "sqlite3", "~> 2.1"
gem "puma", ">= 5.0"
gem "jsbundling-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "cssbundling-rails"
gem "jbuilder"
gem "bcrypt", "~> 3.1.7"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
  gem "webrick"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end