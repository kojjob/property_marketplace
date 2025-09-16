FactoryBot.define do
  factory :booking do
    association :listing
    association :tenant, factory: :user
    check_in_date { 1.week.from_now }
    check_out_date { 2.weeks.from_now }
    status { 'pending' }
    total_price { 500.00 }
    guests_count { 2 }
    message { "Looking forward to staying at your property" }
  end
end