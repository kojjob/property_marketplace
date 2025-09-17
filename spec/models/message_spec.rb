require 'rails_helper'

RSpec.describe Message, type: :model do
  describe 'associations' do
    it { should belong_to(:sender).class_name('User').with_foreign_key('sender_id') }
    it { should belong_to(:recipient).class_name('User').with_foreign_key('recipient_id') }
    it { should belong_to(:conversation) }
    it { should belong_to(:regarding).optional }
  end

  describe 'validations' do
    subject { build(:message) }

    it { should validate_presence_of(:content) }
    it { should validate_length_of(:content).is_at_least(1).is_at_most(5000) }

    describe 'custom validations' do
      context '#sender_and_recipient_different' do
        let(:user) { create(:user) }
        let(:user2) { create(:user) }
        let(:conversation) { create(:conversation, participant1: user, participant2: user2) }

        it 'prevents sending messages to self' do
          message = build(:message, sender: user, recipient: user, conversation: conversation)
          expect(message).not_to be_valid
          expect(message.errors[:recipient]).to include("can't send message to yourself")
        end

        it 'allows messages between different users' do
          sender = create(:user)
          recipient = create(:user)
          conversation_for_test = create(:conversation, participant1: sender, participant2: recipient)
          message = build(:message, sender: sender, recipient: recipient, conversation: conversation_for_test)
          expect(message).to be_valid
        end
      end

      context '#users_in_conversation' do
        let(:user1) { create(:user) }
        let(:user2) { create(:user) }
        let(:user3) { create(:user) }
        let(:conversation) { create(:conversation, participant1: user1, participant2: user2) }

        it 'validates sender is part of conversation' do
          message = build(:message, sender: user3, recipient: user2, conversation: conversation)
          expect(message).not_to be_valid
          expect(message.errors[:sender]).to include("must be part of the conversation")
        end

        it 'validates recipient is part of conversation' do
          message = build(:message, sender: user1, recipient: user3, conversation: conversation)
          expect(message).not_to be_valid
          expect(message.errors[:recipient]).to include("must be part of the conversation")
        end

        it 'allows messages between conversation participants' do
          message = build(:message, sender: user1, recipient: user2, conversation: conversation)
          expect(message).to be_valid
        end
      end
    end
  end

  describe 'enums' do
    it { should define_enum_for(:status)
          .with_values(
            unread: 0,
            read: 1,
            archived: 2,
            deleted: 3
          ) }

    it { should define_enum_for(:message_type)
          .with_values(
            text: 0,
            booking_request: 1,
            booking_confirmation: 2,
            booking_cancellation: 3,
            payment_notification: 4,
            system_message: 5
          ) }
  end

  describe 'scopes' do
    let!(:unread_message) { create(:message, status: 'unread') }
    let!(:read_message) { create(:message, status: 'read') }
    let!(:archived_message) { create(:message, status: 'archived') }
    let!(:deleted_message) { create(:message, status: 'deleted') }
    let!(:recent_message) { create(:message, created_at: 1.hour.ago) }
    let!(:old_message) { create(:message, created_at: 2.months.ago) }

    describe '.unread' do
      it 'returns only unread messages' do
        expect(Message.unread).to include(unread_message)
        expect(Message.unread).not_to include(read_message, archived_message, deleted_message)
      end
    end

    describe '.read' do
      it 'returns only read messages' do
        expect(Message.read).to include(read_message)
        expect(Message.read).not_to include(unread_message, archived_message, deleted_message)
      end
    end

    describe '.not_deleted' do
      it 'returns messages that are not deleted' do
        expect(Message.not_deleted).to include(unread_message, read_message, archived_message)
        expect(Message.not_deleted).not_to include(deleted_message)
      end
    end

    describe '.recent' do
      it 'returns messages from last 30 days' do
        expect(Message.recent).to include(recent_message)
        expect(Message.recent).not_to include(old_message)
      end
    end

    describe '.for_user' do
      let(:user) { create(:user) }
      let(:other_user) { create(:user) }
      let(:third_user) { create(:user) }
      let(:conversation1) { create(:conversation, participant1: user, participant2: other_user) }
      let(:conversation2) { create(:conversation, participant1: third_user, participant2: user) }
      let!(:sent_message) { create(:message, sender: user, recipient: other_user, conversation: conversation1) }
      let!(:received_message) { create(:message, sender: third_user, recipient: user, conversation: conversation2) }
      let!(:other_message) { create(:message) }

      it 'returns messages sent or received by user' do
        expect(Message.for_user(user.id)).to include(sent_message, received_message)
        expect(Message.for_user(user.id)).not_to include(other_message)
      end
    end

    describe '.in_conversation' do
      let(:conversation) { create(:conversation) }
      let!(:conversation_message) { create(:message, conversation: conversation) }
      let!(:other_message) { create(:message) }

      it 'returns messages in specific conversation' do
        expect(Message.in_conversation(conversation.id)).to include(conversation_message)
        expect(Message.in_conversation(conversation.id)).not_to include(other_message)
      end
    end
  end

  describe 'methods' do
    let(:message) { create(:message, status: 'unread') }

    describe '#mark_as_read!' do
      it 'changes status to read' do
        message.mark_as_read!
        expect(message.status).to eq('read')
      end

      it 'sets read_at timestamp' do
        message.mark_as_read!
        expect(message.read_at).to be_present
      end

      it 'does not update read_at if already read' do
        message.update!(status: 'read', read_at: 1.day.ago)
        original_read_at = message.read_at
        message.mark_as_read!
        expect(message.read_at).to eq(original_read_at)
      end
    end

    describe '#mark_as_unread!' do
      let(:read_message) { create(:message, status: 'read', read_at: 1.hour.ago) }

      it 'changes status to unread' do
        read_message.mark_as_unread!
        expect(read_message.status).to eq('unread')
      end

      it 'clears read_at timestamp' do
        read_message.mark_as_unread!
        expect(read_message.read_at).to be_nil
      end
    end

    describe '#archive!' do
      it 'changes status to archived' do
        message.archive!
        expect(message.status).to eq('archived')
      end
    end

    describe '#unarchive!' do
      let(:archived_message) { create(:message, status: 'archived') }

      it 'changes status back to read' do
        archived_message.unarchive!
        expect(archived_message.status).to eq('read')
      end
    end

    describe '#soft_delete!' do
      it 'changes status to deleted' do
        message.soft_delete!
        expect(message.status).to eq('deleted')
      end

      it 'does not actually destroy the record' do
        message.soft_delete!
        expect(Message.unscoped.find(message.id)).to be_present
      end
    end

    describe '#unread?' do
      it 'returns true for unread messages' do
        expect(message.unread?).to be true
      end

      it 'returns false for read messages' do
        message.update!(status: 'read')
        expect(message.unread?).to be false
      end
    end

    describe '#read?' do
      it 'returns false for unread messages' do
        expect(message.read?).to be false
      end

      it 'returns true for read messages' do
        message.update!(status: 'read')
        expect(message.read?).to be true
      end
    end
  end

  describe 'callbacks' do
    describe '#update_conversation_last_message' do
      let(:conversation) { create(:conversation) }
      let(:message) { build(:message, conversation: conversation) }

      it 'updates conversation last_message_at after create' do
        expect {
          message.save!
        }.to change { conversation.reload.last_message_at }
      end

      it 'increments conversation unread count for recipient' do
        expect {
          message.save!
        }.to change { conversation.reload.unread_count_for(message.recipient) }.by(1)
      end
    end

    describe '#notify_recipient' do
      let(:message) { build(:message) }

      it 'enqueues notification job after create' do
        expect {
          message.save!
        }.to have_enqueued_job(MessageNotificationJob).with(message)
      end

      it 'does not notify for system messages' do
        system_message = build(:message, message_type: 'system_message')
        expect {
          system_message.save!
        }.not_to have_enqueued_job(MessageNotificationJob)
      end
    end
  end

  describe 'attachments' do
    let(:message) { create(:message) }

    it 'can have attached images' do
      message.images.attach(
        io: File.open(Rails.root.join('spec/fixtures/test_image.jpg')),
        filename: 'test_image.jpg',
        content_type: 'image/jpeg'
      )
      expect(message.images).to be_attached
    end

    it 'can have attached documents' do
      message.documents.attach(
        io: File.open(Rails.root.join('spec/fixtures/test_document.pdf')),
        filename: 'test_document.pdf',
        content_type: 'application/pdf'
      )
      expect(message.documents).to be_attached
    end
  end
end