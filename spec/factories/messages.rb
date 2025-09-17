FactoryBot.define do
  factory :message do
    # First ensure we have two different users
    transient do
      user1 { create(:user) }
      user2 { create(:user) }
    end

    # Use the transient users as defaults
    sender { user1 }
    recipient { user2 }

    # Create conversation with these users
    conversation { association(:conversation, participant1: sender, participant2: recipient) }

    content { "This is a test message content that meets the minimum length requirement." }
    status { 'unread' }
    message_type { 'text' }

    # After building, ensure consistency between conversation and participants
    after(:build) do |message, evaluator|
      # If a conversation was explicitly provided, use its participants
      if message.conversation && message.conversation.persisted? &&
         message.conversation.participant1 && message.conversation.participant2
        # Only override if sender/recipient weren't explicitly set to something else
        if message.sender_id.nil? || message.sender == evaluator.user1
          message.sender = message.conversation.participant1
        end
        if message.recipient_id.nil? || message.recipient == evaluator.user2
          message.recipient = message.conversation.participant2
        end
      end
    end

    trait :read do
      status { 'read' }
      read_at { 1.hour.ago }
    end

    trait :archived do
      status { 'archived' }
    end

    trait :deleted do
      status { 'deleted' }
    end

    trait :with_images do
      after(:create) do |message|
        message.images.attach(
          io: StringIO.new("fake image data"),
          filename: 'test_image.jpg',
          content_type: 'image/jpeg'
        )
      end
    end

    trait :with_documents do
      after(:create) do |message|
        message.documents.attach(
          io: StringIO.new("fake document data"),
          filename: 'test_document.pdf',
          content_type: 'application/pdf'
        )
      end
    end

    trait :booking_request do
      message_type { 'booking_request' }
      association :regarding, factory: :booking
    end

    trait :system_message do
      message_type { 'system_message' }
      content { "System notification: Your booking has been confirmed." }
    end
  end
end