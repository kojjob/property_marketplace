FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    confirmed_at { Time.current } # Auto-confirm for tests

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :admin do
      role { 'admin' }
    end

    trait :host do
      role { 'host' }
    end
  end
end
