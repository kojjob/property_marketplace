FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    confirmed_at { Time.current } # Auto-confirm for tests

    after(:create) do |user|
      create(:profile, user: user) if user.profile.blank?
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :admin do
      after(:create) do |user|
        user.profile.update(role: 'admin')
      end
    end

    trait :host do
      after(:create) do |user|
        user.profile.update(role: 'host')
      end
    end
  end
end
