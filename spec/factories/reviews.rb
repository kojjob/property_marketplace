FactoryBot.define do
  factory :review do
    association :reviewable, factory: :listing
    association :reviewer, factory: :user
    booking { nil }
    rating { 4 }
    title { "Great place to stay" }
    content { "The property was clean, well-maintained, and exactly as described in the listing." }
    review_type { 'property_general' }
    status { 'pending' }
    helpful_count { 0 }
    response { nil }
    response_by_id { nil }

    trait :published do
      status { 'published' }
    end

    trait :with_booking do
      association :booking
      review_type { 'tenant_to_property' }
    end

    trait :high_rating do
      rating { 5 }
      title { "Excellent experience!" }
      content { "Absolutely perfect stay. Everything exceeded expectations and the host was amazing." }
    end

    trait :low_rating do
      rating { 1 }
      title { "Disappointing experience" }
      content { "Unfortunately, the property did not meet expectations and had several issues." }
    end

    trait :with_response do
      response { "Thank you for your feedback. We appreciate your review." }
      response_by_id { 1 }
    end

    trait :flagged do
      status { 'flagged' }
    end
  end
end