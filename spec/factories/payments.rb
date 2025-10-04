FactoryBot.define do
  factory :payment do
    association :booking, factory: :booking
    association :payer, factory: :user
    association :payee, factory: :user

    amount { 1000.00 }
    currency { 'USD' }
    status { 'pending' }
    payment_type { 'deposit' }  # Default to deposit to avoid booking total validation
    payment_method { 'credit_card' }
    service_fee { amount * 0.03 } # 3% service fee

    after(:build) do |payment|
      # Set booking to confirmed status for payment validation ONLY if it's pending
      if payment.booking && payment.booking.status == 'pending'
        payment.booking.status = 'confirmed'
      end
    end

    trait :full_payment do
      payment_type { 'full_payment' }

      after(:build) do |payment|
        # For full payments, ensure booking total matches payment amount
        if payment.booking
          payment.booking.total_amount = payment.amount
        end
      end
    end

    trait :completed do
      status { 'completed' }
      processed_at { 1.hour.ago }
    end

    trait :failed do
      status { 'failed' }
      processed_at { 1.hour.ago }
      failure_reason { 'Insufficient funds' }
    end

    trait :refunded do
      status { 'refunded' }
      processed_at { 2.days.ago }
      refunded_at { 1.day.ago }
    end

    trait :deposit do
      payment_type { 'deposit' }
      amount { 200.00 }
    end

    trait :security_deposit do
      payment_type { 'security_deposit' }
      amount { 500.00 }
    end

    trait :with_reference do
      transaction_reference { "REF-#{Faker::Alphanumeric.alphanumeric(number: 10).upcase}" }
    end
  end
end
