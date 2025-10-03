FactoryBot.define do
  factory :blog_post do
    association :user
    title { Faker::Lorem.sentence(word_count: 5) }
    content { Faker::Lorem.paragraph(sentence_count: 10) }
    excerpt { Faker::Lorem.paragraph(sentence_count: 2) }
    slug { nil } # Will be generated from title
    published { false }
    published_at { nil }
    meta_title { Faker::Lorem.sentence(word_count: 3) }
    meta_description { Faker::Lorem.paragraph(sentence_count: 1) }
    meta_keywords { Faker::Lorem.words(number: 5).join(', ') }

    # Remove featured_image_url since we now use Active Storage
    # featured_image_url { Faker::Internet.url }

    trait :published do
      published { true }
      published_at { Faker::Time.backward(days: 30) }
    end

    trait :draft do
      published { false }
      published_at { nil }
    end

    trait :with_categories do
      after(:create) do |blog_post|
        create_list(:blog_category, 2, blog_posts: [ blog_post ])
      end
    end
  end
end
