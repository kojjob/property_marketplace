# 🏡 Property Marketplace Platform - TDD Implementation Plan with Rails 8 Native Stack

## Current State Analysis
Your Rails 8 application has:
- ✅ Rails 8.0.2 with PostgreSQL
- ✅ **Solid Cache, Solid Queue, Solid Cable** (No Redis/Sidekiq needed!)
- ✅ Built-in Rails 8 authentication (keep existing, enhance later)
- ✅ Property model with geolocation
- ✅ RSpec testing framework configured
- ✅ Kamal for deployment

## 🧪 TDD-First Implementation Strategy

### Phase 1: Enhanced Domain Models with TDD (Week 1)

#### 1.1 Required Gems (Rails 8 Native Focus)
```ruby
# Core functionality (NO Redis, NO Sidekiq!)
gem "pundit"          # Authorization
gem "rgeo"            # Geospatial features
gem "neighbor"        # pgvector for AI embeddings
gem "geocoder"        # Address geocoding

# Search & Analytics (using PostgreSQL)
gem "pg_search"       # PostgreSQL full-text search (instead of Elasticsearch)
gem "ahoy_matey"      # Event tracking
gem "chartkick"       # Charts
gem "groupdate"       # Time series data

# Performance (Rails 8 native)
gem "rack-attack"     # Rate limiting
# NOTE: Using Solid Queue instead of Sidekiq
# NOTE: Using Solid Cache instead of Redis

# Payments & External Services
gem "pay"             # Payment processing (Stripe, Paddle, etc.)
gem "aws-sdk-s3"      # S3 for Active Storage
gem "twilio-ruby"     # SMS notifications
gem "postmark-rails"   # Transactional email

# AI/ML Integration
gem "ruby-openai"     # OpenAI integration
gem "tiktoken_ruby"   # Token counting

# Development & Testing
gem "annotate"        # Model annotations
gem "bullet"          # N+1 query detection
gem "letter_opener"   # Email preview in dev
gem "simplecov"       # Test coverage
gem "webmock"         # Mock external API calls
gem "vcr"            # Record API interactions
```

#### 1.2 TDD Workflow for Each Feature

**Every feature follows this TDD cycle:**
1. **Write failing spec first**
2. **Implement minimal code to pass**
3. **Refactor with confidence**
4. **Ensure 90%+ test coverage**

### Phase 2: Core Models with TDD (Week 1-2)

#### 2.1 Test-First Model Development

```ruby
# Start with specs for each model:

# spec/models/profile_spec.rb
RSpec.describe Profile do
  it { should belong_to(:user) }
  it { should validate_presence_of(:first_name) }
  it { should define_enum_for(:role).with_values(tenant: 0, landlord: 1, agent: 2, admin: 3) }
  # Write ALL specs before implementing model
end

# spec/models/listing_spec.rb
RSpec.describe Listing do
  it { should belong_to(:property) }
  it { should have_many(:bookings) }
  it { should define_enum_for(:listing_type).with_values(rent: 0, sale: 1, short_term: 2) }
  it { should monetize(:price) }
  # Complete spec suite first
end
```

**Models to implement (TDD):**
- ✅ `Profile` - Extended user information
- ✅ `Listing` - Property listings with pricing
- `Booking` - Reservation system
- `Payment` - Transaction records
- `Review` - Rating system
- `Message` - Communication (with ActionCable)
- `Verification` - Document verification
- `AuditLog` - Compliance tracking
- `AIEmbedding` - pgvector for recommendations
- `Amenity` - Property features
- `ListingAmenity` - Join table

### Phase 3: Service Objects with TDD (Week 2-3)

#### 3.1 Test-First Service Architecture

```ruby
# spec/services/property/search_service_spec.rb
RSpec.describe Property::SearchService do
  describe '#call' do
    context 'with location filters' do
      it 'returns properties within radius'
      it 'orders by distance'
      it 'applies price filters'
    end

    context 'with AI recommendations' do
      it 'uses pgvector for similarity search'
      it 'personalizes based on user history'
    end
  end
end
```

**Service Objects (all TDD):**
```
app/services/
├── ai/
│   ├── recommendation_service.rb (with pgvector)
│   ├── embedding_generator.rb
│   └── fraud_detector.rb
├── property/
│   ├── search_service.rb (PostgreSQL full-text)
│   ├── valuation_service.rb
│   └── verification_service.rb
├── payment/
│   ├── payment_processor.rb (using Pay gem)
│   └── subscription_manager.rb
└── notification/
    ├── notifier.rb (Solid Queue jobs)
    └── broadcaster.rb (Solid Cable)
```

### Phase 4: Background Jobs with Solid Queue (Week 3)

#### 4.1 TDD for Background Jobs

```ruby
# spec/jobs/property_indexing_job_spec.rb
RSpec.describe PropertyIndexingJob do
  it 'generates AI embeddings' do
    property = create(:property)

    expect {
      described_class.perform_now(property.id)
    }.to change { property.reload.embedding_vector }.from(nil)
  end

  it 'updates search index' do
    # Test PostgreSQL full-text search index update
  end
end
```

**Solid Queue Jobs (all TDD):**
- `PropertyIndexingJob` - Generate embeddings & search index
- `EmailNotificationJob` - Transactional emails
- `ImageProcessingJob` - Active Storage variants
- `RecommendationJob` - AI recommendations
- `AnalyticsJob` - Event processing
- `VerificationJob` - Document verification

### Phase 5: API Development with TDD (Week 4)

#### 5.1 Request Specs First

```ruby
# spec/requests/api/v1/properties_spec.rb
RSpec.describe "API V1 Properties" do
  describe "GET /api/v1/properties" do
    it "returns paginated properties"
    it "filters by location"
    it "includes AI recommendations"
    it "requires authentication for premium features"
  end

  describe "POST /api/v1/properties/:id/book" do
    it "creates booking with Solid Queue job"
    it "processes payment via Pay gem"
    it "broadcasts via Solid Cable"
  end
end
```

### Phase 6: Real-time Features with Solid Cable (Week 5)

#### 6.1 TDD for ActionCable

```ruby
# spec/channels/property_channel_spec.rb
RSpec.describe PropertyChannel do
  it "subscribes to property updates"
  it "broadcasts price changes"
  it "handles availability updates"
end

# spec/system/real_time_chat_spec.rb
RSpec.describe "Real-time Chat", type: :system do
  it "delivers messages instantly via Solid Cable"
  it "shows typing indicators"
  it "handles presence tracking"
end
```

### Phase 7: AI/ML Features with TDD (Week 6)

#### 7.1 Test-First AI Integration

```ruby
# spec/services/ai/recommendation_service_spec.rb
RSpec.describe AI::RecommendationService do
  describe '#generate_recommendations' do
    before do
      # Use VCR to record OpenAI API calls
      VCR.use_cassette('openai_recommendations')
    end

    it 'generates property embeddings using OpenAI'
    it 'stores vectors in PostgreSQL using neighbor gem'
    it 'finds similar properties using cosine similarity'
    it 'personalizes based on user preferences'
  end
end
```

### Phase 8: Performance & Caching with TDD (Week 7)

#### 8.1 Solid Cache Testing

```ruby
# spec/services/cache_service_spec.rb
RSpec.describe CacheService do
  it "caches expensive queries with Solid Cache"
  it "invalidates cache on updates"
  it "handles cache stampedes"

  describe 'performance' do
    it 'serves cached responses in <10ms'
    it 'reduces database queries by 80%'
  end
end
```

### Phase 9: System Testing (Week 8)

#### 9.1 End-to-End Testing

```ruby
# spec/system/user_journey_spec.rb
RSpec.describe "Complete User Journey", type: :system do
  it "allows users to search, view, and book properties" do
    # Test complete flow with Capybara
    visit root_path
    fill_in "Location", with: "San Francisco"
    click_button "Search"

    expect(page).to have_content("AI Recommended")

    click_link "View Property"
    click_button "Book Now"

    # Test Solid Queue job processing
    expect(EmailNotificationJob).to have_been_enqueued

    # Test Solid Cable real-time updates
    expect(page).to have_content("Booking Confirmed")
  end
end
```

### Phase 10: Security & Compliance with TDD (Week 9)

#### 10.1 Security Testing

```ruby
# spec/security/authentication_spec.rb
RSpec.describe "Authentication Security" do
  it "prevents session fixation"
  it "implements CSRF protection"
  it "rate limits login attempts"
  it "logs security events for audit"
end

# spec/policies/property_policy_spec.rb
RSpec.describe PropertyPolicy do
  subject { described_class.new(user, property) }

  context "as tenant" do
    it { should permit(:show) }
    it { should_not permit(:edit) }
  end

  context "as landlord" do
    it { should permit(:edit) }
    it { should permit(:destroy) }
  end
end
```

## 📊 Key Architecture Decisions

### Why Rails 8 Native Stack?

1. **Solid Cache** > Redis
   - Database-backed, no separate infrastructure
   - Larger cache capacity (disk-based)
   - Built-in encryption

2. **Solid Queue** > Sidekiq
   - No Redis dependency
   - Database-backed reliability
   - Mission-critical job handling
   - Recurring job support built-in

3. **Solid Cable** > Redis Pub/Sub
   - Database-backed WebSockets
   - Message persistence for debugging
   - No separate infrastructure

4. **PostgreSQL Full-Text Search** > Elasticsearch
   - Simpler infrastructure
   - Good enough for most use cases
   - pgvector for AI embeddings

## 🎯 Testing Metrics Goals

- **Code Coverage**: Minimum 90%
- **Test Suite Speed**: <2 minutes for unit tests
- **System Tests**: Cover all critical user journeys
- **API Tests**: 100% endpoint coverage
- **Performance Tests**: Sub-200ms response times

## 🚀 Deployment with Kamal

```yaml
# config/deploy.yml
service: property_marketplace
image: property_marketplace

servers:
  web:
    - your-server.com

env:
  clear:
    RAILS_SERVE_STATIC_FILES: true
    RAILS_LOG_TO_STDOUT: true
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL

accessories:
  db:
    image: postgres:16
    port: 5432
    env:
      secret:
        - POSTGRES_PASSWORD
```

## 📈 Development Workflow

1. **Every PR requires:**
   - All tests passing
   - 90%+ coverage for new code
   - No N+1 queries (Bullet gem)
   - Performance benchmarks
   - Security scan (Brakeman)

2. **TDD Cycle for Every Feature:**
   - Write failing test
   - Write minimal code to pass
   - Refactor
   - Ensure all tests still pass
   - Check coverage

3. **Continuous Integration:**
   - GitHub Actions for test runs
   - Automatic deployment with Kamal
   - Performance monitoring
   - Error tracking

## 🏗️ Current Implementation Progress

### ✅ Completed
- [x] Created feature branch
- [x] Updated Gemfile with Rails 8 native gems
- [x] Installed dependencies
- [x] Created Profile model with TDD
- [x] Created Listing model specs (TDD red phase)

### 🚧 In Progress
- [ ] Implementing Listing model to pass specs
- [ ] Creating Booking model with TDD

### 📋 Next Steps
1. Complete Listing model implementation
2. Create Booking model with full TDD
3. Implement core service objects
4. Set up Solid Queue jobs
5. Create API endpoints
6. Implement real-time features with Solid Cable
7. Add AI recommendations with pgvector
8. Complete security implementation
9. Deploy with Kamal

## 🔑 Key Differentiators

1. **AI-Driven Personalization**: ML models for hyper-personalized recommendations
2. **Predictive Analytics**: Neighborhood scoring & property value forecasting
3. **Trust Layer**: Comprehensive verification system
4. **Subscription Living**: Flexible monthly rental packages
5. **Community Features**: Roommate matching & neighborhood forums
6. **End-to-End Platform**: Integrated services from search to move-out
7. **Immersive Experience**: AR/VR tours & virtual staging (future phase)

This plan leverages Rails 8's native capabilities, eliminates unnecessary dependencies, and ensures rock-solid quality through comprehensive TDD practices.