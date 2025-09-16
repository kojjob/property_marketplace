FactoryBot.define do
  factory :conversation do
    association :participant1, factory: :user
    association :participant2, factory: :user

    # Ensure participants are different
    after(:build) do |conversation|
      if conversation.participant1 == conversation.participant2
        conversation.participant2 = create(:user)
      end
    end

    trait :with_messages do
      after(:create) do |conversation|
        create_list(:message, 3,
          conversation: conversation,
          sender: conversation.participant1,
          recipient: conversation.participant2
        )
      end
    end

    trait :archived do
      archived { true }
      archived_at { 1.day.ago }
    end
  end
end