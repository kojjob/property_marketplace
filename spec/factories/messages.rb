FactoryBot.define do
  factory :message do
    sender { association :user }
    recipient { association :user }
    conversation { association :conversation, participant1: sender, participant2: recipient }

    content { "This is a test message content that meets the minimum length requirement." }
    status { 'unread' }
    message_type { 'text' }

    # When a conversation is provided externally (in tests), use its participants
    after(:build) do |message|
      if message.conversation &&
         (!message.conversation.participant?(message.sender) ||
          !message.conversation.participant?(message.recipient))
        # Use the conversation's participants if the message participants don't match
        message.sender = message.conversation.participant1
        message.recipient = message.conversation.participant2
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