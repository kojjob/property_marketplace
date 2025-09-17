FactoryBot.define do
  factory :property do
    association :user
    title { Faker::Lorem.sentence(word_count: 5) }
    description { Faker::Lorem.paragraph(sentence_count: 5) }
    price { Faker::Number.decimal(l_digits: 6, r_digits: 2) }
    property_type { Property::PROPERTY_TYPES.sample }
    bedrooms { Faker::Number.between(from: 1, to: 5) }
    bathrooms { Faker::Number.between(from: 1, to: 3) }
    square_feet { Faker::Number.between(from: 500, to: 5000) }
    address { Faker::Address.street_address }
    city { Faker::Address.city }
    region { Faker::Address.state_abbr }
    postal_code { Faker::Address.zip_code }
    status { 'active' }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }

    trait :sold do
      status { 'sold' }
    end

    trait :pending do
      status { 'pending' }
    end

    trait :commercial do
      property_type { 'Commercial' }
      bedrooms { nil }
      bathrooms { nil }
    end
  end
end