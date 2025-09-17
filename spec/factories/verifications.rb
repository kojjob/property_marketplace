FactoryBot.define do
  factory :verification do
    association :user
    verification_type { 'email' }
    status { 'pending' }

    # Set document_url based on verification type
    document_url do
      if verification_type && [ 'identity', 'address', 'background_check', 'income' ].include?(verification_type)
        "https://example.com/documents/#{verification_type}_#{SecureRandom.uuid}.pdf"
      end
    end

    trait :email do
      verification_type { 'email' }
      document_url { nil }
    end

    trait :phone do
      verification_type { 'phone' }
      document_url { nil }
    end

    trait :identity do
      verification_type { 'identity' }
      document_url { "https://example.com/documents/identity_#{SecureRandom.uuid}.pdf" }
    end

    trait :address do
      verification_type { 'address' }
      document_url { "https://example.com/documents/address_#{SecureRandom.uuid}.pdf" }
    end

    trait :background_check do
      verification_type { 'background_check' }
      document_url { "https://example.com/documents/background_#{SecureRandom.uuid}.pdf" }
    end

    trait :income do
      verification_type { 'income' }
      document_url { "https://example.com/documents/income_#{SecureRandom.uuid}.pdf" }
    end

    trait :pending do
      status { 'pending' }
    end

    trait :in_review do
      status { 'in_review' }
    end

    trait :approved do
      status { 'approved' }
      association :verified_by, factory: :user
      verified_at { 1.hour.ago }
    end

    trait :rejected do
      status { 'rejected' }
      association :verified_by, factory: :user
      verified_at { 1.hour.ago }
      rejection_reason { 'Document not valid' }
    end

    trait :expired do
      status { 'expired' }
      expired_at { 1.day.ago }
      expires_at { 2.days.ago }
    end

    trait :with_documents do
      after(:create) do |verification|
        verification.documents.attach(
          io: StringIO.new("fake document data"),
          filename: "verification_document.pdf",
          content_type: 'application/pdf'
        )
      end
    end
  end
end
