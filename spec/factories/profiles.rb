FactoryBot.define do
  factory :profile do
    association :user
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    phone_number { Faker::PhoneNumber.phone_number }
    date_of_birth { Faker::Date.birthday(min_age: 18, max_age: 65) }
    bio { Faker::Lorem.paragraph }
    role { 'tenant' }
    verification_status { 'unverified' }

    trait :landlord do
      role { 'landlord' }
    end

    trait :agent do
      role { 'agent' }
    end

    trait :admin do
      role { 'admin' }
    end

    trait :verified do
      verification_status { 'verified' }
    end

    trait :pending do
      verification_status { 'pending' }
    end
  end
end
