FactoryBot.define do
  factory :comment do
    association :blog_post
    content { Faker::Lorem.paragraph(sentence_count: 2) }
    status { 'pending' }

    # Default to guest comment
    user { nil }
    author_name { Faker::Name.name }
    author_email { Faker::Internet.email }

    trait :approved do
      status { 'approved' }
      approved_at { Time.current }
    end

    trait :pending do
      status { 'pending' }
    end

    trait :rejected do
      status { 'rejected' }
    end

    trait :from_user do
      association :user
      author_name { nil }
      author_email { nil }
    end

    trait :guest do
      user { nil }
      author_name { Faker::Name.name }
      author_email { Faker::Internet.email }
    end

    trait :reply do
      association :parent, factory: :comment
    end
  end
end
