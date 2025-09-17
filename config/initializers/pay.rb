# Pay gem configuration
Pay.setup do |config|
  # Application information
  config.application_name = "Property Marketplace"
  config.business_name = "Property Marketplace Platform"
  config.business_address = "123 Main St, Anytown, USA"
  config.support_email = "support@propertymarketplace.com"

  # Email receipts configuration
  config.send_emails = true
end

# Stripe configuration will be set via credentials
if Rails.application.credentials.stripe&.secret_key
  Stripe.api_key = Rails.application.credentials.stripe.secret_key
  Stripe.api_version = "2023-10-16"
end