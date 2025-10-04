FactoryBot.define do
  factory :favorite do
    association :user
    association :property
  end
end
