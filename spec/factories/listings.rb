FactoryBot.define do
  factory :listing do
    association :property
    association :user
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph }
    price { Faker::Number.between(from: 500, to: 5000) }
    listing_type { 'rent' }
    status { 'active' }
    available_from { Date.today }
    lease_duration { 12 }
    lease_duration_unit { 'months' }
    minimum_stay { 1 }
    maximum_stay { nil }

    trait :for_sale do
      listing_type { 'sale' }
      price { Faker::Number.between(from: 100_000, to: 1_000_000) }
      lease_duration { nil }
      lease_duration_unit { nil }
    end

    trait :short_term do
      listing_type { 'short_term' }
      price { Faker::Number.between(from: 100, to: 500) }
      lease_duration { 1 }
      lease_duration_unit { 'days' }
      minimum_stay { 2 }
      maximum_stay { 30 }
    end

    trait :subscription do
      listing_type { 'subscription' }
      price { Faker::Number.between(from: 2000, to: 5000) }
      lease_duration { 1 }
      lease_duration_unit { 'months' }
    end

    trait :active do
      status { 'active' }
      available_from { 1.day.ago }
    end

    trait :inactive do
      status { 'inactive' }
    end

    trait :draft do
      status { 'draft' }
    end
  end
end
