FactoryBot.define do
  factory :saved_search do
    user { nil }
    name { "MyString" }
    criteria { "" }
    frequency { 1 }
    last_run_at { "2025-09-17 11:16:46" }
  end
end
