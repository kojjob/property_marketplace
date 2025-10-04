source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2", ">= 8.0.2.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# Authentication and Authorization
gem "devise", "~> 4.9"            # Authentication solution
gem "pundit", "~> 2.3"           # Authorization policies
gem "rack-attack", "~> 6.7"      # Rate limiting and throttling

# Geospatial and Search
gem "geocoder", "~> 1.8"          # Address geocoding
gem "pg_search", "~> 2.3"         # PostgreSQL full-text search
# gem "neighbor", "~> 0.3"          # pgvector for AI embeddings - Add later when pgvector is installed

# Analytics and Tracking
# gem "ahoy_matey", "~> 5.0"        # Event tracking - Commented out for now
# gem "chartkick", "~> 5.0"         # Charts - Commented out for now
# gem "groupdate", "~> 6.4"         # Time series data - Commented out for now

 # Payments
 gem "pay", "~> 7.0"               # Payment processing (Stripe, Paddle, etc.)
 gem "stripe", "~> 12.0"           # Stripe API

 # API Authentication
 gem "jwt", "~> 2.8"               # JSON Web Tokens for API authentication

# External Services
gem "aws-sdk-s3", "~> 1.140"      # S3 for Active Storage
gem "twilio-ruby", "~> 7.8"       # SMS notifications
gem "postmark-rails", "~> 0.22"   # Transactional email

# AI/ML Integration
# gem "ruby-openai", "~> 6.3"       # OpenAI integration - Add when needed
# gem "tiktoken_ruby", "~> 0.0.8"   # Token counting - Add when needed

# Background Jobs (using Solid Queue - already included)
# NOTE: Solid Queue is already included in Rails 8

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # RSpec testing framework
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails"
  gem "faker"
  gem "rails-controller-testing"

  # Additional testing tools
  gem "simplecov", require: false   # Test coverage
  gem "webmock"                     # Mock external API calls
  gem "vcr"                         # Record API interactions
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Development productivity
  gem "annotate"          # Annotate models with schema info
  gem "bullet"            # N+1 query detection
  gem "letter_opener"     # Preview emails in browser
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers", "~> 6.0"
  gem "database_cleaner-active_record"
  gem "timecop"  # For time-based testing
end
