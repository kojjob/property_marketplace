FactoryBot.define do
  factory :blog_category do
    sequence(:name) { |n| "Category #{n}" }
    sequence(:slug) { |n| "category-#{n}" }
    description { "A description for this blog category" }

    trait :with_posts do
      after(:create) do |category|
        blog_posts = create_list(:blog_post, 3)
        blog_posts.each do |blog_post|
          create(:blog_post_category, blog_post: blog_post, blog_category: category)
        end
      end
    end

    trait :property_management do
      name { "Property Management" }
      slug { "property-management" }
      description { "Tips and advice for managing rental properties" }
    end

    trait :real_estate_trends do
      name { "Real Estate Trends" }
      slug { "real-estate-trends" }
      description { "Latest trends and insights in the real estate market" }
    end
  end
end
