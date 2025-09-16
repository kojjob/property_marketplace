FactoryBot.define do
  factory :property_image do
    association :property
    image_url { Faker::LoremFlickr.image(size: "800x600", search_terms: ['house', 'property']) }
    caption { Faker::Lorem.sentence(word_count: 3) }
    position { Faker::Number.between(from: 0, to: 10) }
  end
end