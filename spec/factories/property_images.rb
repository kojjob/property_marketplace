FactoryBot.define do
  factory :property_image do
    association :property
    caption { Faker::Lorem.sentence(word_count: 3) }
    position { 0 }

    # Attach a test image using Active Storage
    after(:build) do |property_image|
      property_image.image.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg')),
        filename: 'test_image.jpg',
        content_type: 'image/jpeg'
      )
    end

    trait :with_custom_position do
      position { rand(0..10) }
    end

    trait :primary do
      position { 0 }
    end

    trait :secondary do
      position { 1 }
    end

    trait :without_image do
      after(:build) do |property_image|
        # Don't attach any image for testing validation failures
        property_image.image = nil
      end
    end

    trait :with_large_image do
      after(:build) do |property_image|
        # For testing file size validation - we'll stub the byte_size in specs
        property_image.image.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg')),
          filename: 'large_test_image.jpg',
          content_type: 'image/jpeg'
        )
      end
    end

    # Legacy support for image_url field
    trait :with_image_url do
      image_url { Faker::LoremFlickr.image(size: "800x600", search_terms: ['house', 'property']) }

      after(:build) do |property_image|
        # Don't attach Active Storage image when using URL
        property_image.image = nil
      end
    end
  end
end