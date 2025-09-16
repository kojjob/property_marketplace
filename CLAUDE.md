# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Property Marketplace Platform** built with Rails 8.0.2, utilizing the Rails 8 "Trifecta" (Solid Queue, Solid Cache, Solid Cable) for background jobs, caching, and WebSockets without requiring Redis. The project follows Test-Driven Development (TDD) with RSpec.

## Essential Commands

### Development Setup
```bash
# Install dependencies
bundle install

# Database setup
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed

# Start development server
bin/dev  # Uses Procfile.dev for all services
```

### Testing Commands
```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# Run specific test by line number
bundle exec rspec spec/models/user_spec.rb:42

# Run with coverage report
COVERAGE=true bundle exec rspec

# Run system tests
bundle exec rspec spec/system
```

### Code Quality
```bash
# Run Rubocop for style violations
bundle exec rubocop

# Auto-fix Rubocop issues
bundle exec rubocop -a

# Security scan with Brakeman
bundle exec brakeman

# Check for N+1 queries (Bullet gem logs to console in development)
```

### Database & Migrations
```bash
# Create new migration
bin/rails generate migration AddFieldToModel field:type

# Rollback migration
bin/rails db:rollback

# Check migration status
bin/rails db:migrate:status

# Annotate models with schema info
bundle exec annotate --models
```

### Background Jobs (Solid Queue)
```bash
# Process jobs (automatically started with bin/dev)
bin/jobs

# Open Rails console with jobs access
bin/rails console
SolidQueue::Job.all  # View all jobs
```

### Deployment (Kamal)
```bash
# Initial setup
kamal setup

# Deploy
kamal deploy

# View logs
kamal app logs -f

# Console on production
kamal app exec --interactive "bin/rails console"
```

## Architecture & Key Design Decisions

### Rails 8 Native Stack
- **NO Redis/Sidekiq**: Using Solid Queue (database-backed) for background jobs
- **NO Elasticsearch**: Using PostgreSQL full-text search with pg_search gem
- **NO External Cache**: Using Solid Cache (database-backed) instead of Redis/Memcached
- **WebSockets**: Solid Cable (database-backed) for real-time features

### Core Models & Relationships
```ruby
User
  has_one :profile
  has_many :properties
  has_many :listings (through properties)
  has_many :bookings (as tenant or landlord)
  has_many :reviews
  has_many :sessions  # Rails 8 authentication

Profile
  belongs_to :user
  enum role: { tenant: 0, landlord: 1, agent: 2, admin: 3 }
  enum verification_status: { unverified: 0, pending: 1, verified: 2 }

Property
  belongs_to :user
  has_many :listings
  has_many :property_images
  # Uses geocoder for lat/lng

Listing
  belongs_to :property
  belongs_to :user
  has_many :bookings
  enum listing_type: { rent: 0, sale: 1, short_term: 2, subscription: 3 }
  enum status: { draft: 0, active: 1, inactive: 2, archived: 3 }

Booking
  belongs_to :listing
  belongs_to :tenant (User)
  belongs_to :landlord (User)
  enum status: { pending: 0, confirmed: 1, cancelled: 2, completed: 3 }
```

### Service Object Pattern
All business logic lives in service objects under `app/services/`:
```ruby
# Example: Property::SearchService.new(params).call
# Returns ServiceResult object with success/failure state
```

### Authentication
Using Rails 8's built-in authentication (not Devise):
- Session-based authentication
- `app/controllers/concerns/authentication.rb` module
- Password reset via `PasswordsController`

### Testing Strategy
- **TDD Required**: Write specs first, then implementation
- **Coverage Goal**: Minimum 90% test coverage
- **Factory Bot**: Use factories, not fixtures
- **VCR**: Record external API calls (OpenAI, Stripe, etc.)

### Key Gems & Their Purpose
- `pay`: Payment processing abstraction (Stripe, Paddle)
- `pg_search`: PostgreSQL full-text search
- `geocoder`: Address geocoding and location features
- `pundit`: Authorization policies
- `ahoy_matey`: Event tracking and analytics
- `image_processing`: Active Storage image variants
- `postmark-rails`: Transactional email

### API Design
- RESTful endpoints under `/api/v1/`
- JSON responses using Jbuilder
- Token authentication for API access (future)
- Rate limiting with rack-attack

### Performance Considerations
- Use `includes` to avoid N+1 queries
- Bullet gem configured for development
- Solid Cache for expensive queries
- Background jobs for heavy processing
- Image variants processed asynchronously

### Current Implementation Status
- ✅ User authentication (Rails 8 built-in)
- ✅ Profile model with roles and verification
- 🚧 Listing model (specs written, implementation pending)
- ⏳ Booking system
- ⏳ Payment integration
- ⏳ AI recommendations (pgvector ready)

## Project Files Reference

### Key Configuration Files
- `config/database.yml`: PostgreSQL configuration
- `config/deploy.yml`: Kamal deployment settings
- `config/cable.yml`: Solid Cable (ActionCable) config
- `config/cache.yml`: Solid Cache configuration
- `config/queue.yml`: Solid Queue job processing

### Important Documentation
- `IMPLEMENTATION_PLAN.md`: Technical roadmap and architecture decisions
- `AGILE_PROJECT_PLAN.md`: Sprint planning, user stories, and project management

### Environment Variables Required
```
RAILS_MASTER_KEY       # For credentials
DATABASE_URL           # Production database
KAMAL_REGISTRY_PASSWORD # Docker registry
STRIPE_PUBLISHABLE_KEY # Payment processing
STRIPE_SECRET_KEY      # Payment processing
POSTMARK_API_TOKEN     # Email delivery
AWS_ACCESS_KEY_ID      # S3 for Active Storage
AWS_SECRET_ACCESS_KEY  # S3 for Active Storage
```

## Development Workflow

1. Always create a feature branch from main
2. Write specs first (TDD)
3. Implement minimal code to pass specs
4. Refactor while keeping tests green
5. Ensure test coverage remains >90%
6. Run rubocop before committing
7. Create PR with passing CI checks
8. Merge to main after review

## Common Pitfalls to Avoid

- Don't use Redis-dependent gems (we use Solid Queue/Cache/Cable)
- Don't bypass the service object pattern for complex logic
- Don't commit without running tests
- Don't forget to add database indexes for foreign keys and commonly queried fields
- Don't store sensitive data in code (use Rails credentials)