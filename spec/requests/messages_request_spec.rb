require 'rails_helper'

RSpec.describe "Messages", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:conversation) { create(:conversation, participant1: user, participant2: other_user) }
  let!(:message1) { create(:message, conversation: conversation, sender: other_user, recipient: user) }
  let!(:message2) { create(:message, conversation: conversation, sender: user, recipient: other_user) }

  # Sign in user for testing core functionality
  before do
    sign_in user
  end

  describe "GET /conversations/:conversation_id/messages" do
    context "when conversation is provided" do
      it "returns successful response" do
        get conversation_messages_path(conversation)
        expect(response).to have_http_status(:success)
      end

      it "returns JSON response when format is JSON" do
        get conversation_messages_path(conversation), headers: { "Accept" => "application/json" }
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')
      end
    end

    context "when user is not participant in conversation" do
      let(:unauthorized_conversation) { create(:conversation) }

      it "returns 404" do
        expect {
          get conversation_messages_path(unauthorized_conversation)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "GET /messages/:id" do
    context "when user is participant in conversation" do
      it "returns successful response" do
        get message_path(message1)
        expect(response).to have_http_status(:success)
      end

      it "marks message as read if user is recipient" do
        unread_message = create(:message,
          conversation: conversation,
          sender: other_user,
          recipient: user,
          status: 'unread'
        )

        get message_path(unread_message)
        expect(unread_message.reload.status).to eq('read')
      end
    end

    context "when user is not participant in conversation" do
      let(:unauthorized_message) { create(:message) }

      it "returns 404" do
        expect {
          get message_path(unauthorized_message)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "POST /conversations/:conversation_id/messages" do
    let(:valid_attributes) do
      {
        content: "This is a test message"
      }
    end

    context "with valid parameters" do
      it "creates a new message" do
        expect {
          post conversation_messages_path(conversation), params: { message: valid_attributes }
        }.to change(Message, :count).by(1)
      end

      it "creates message with correct attributes" do
        post conversation_messages_path(conversation), params: { message: valid_attributes }
        message = Message.last
        expect(message.content).to eq("This is a test message")
        expect(message.sender).to eq(user)
        expect(message.recipient).to eq(other_user)
        expect(message.conversation).to eq(conversation)
      end

      it "redirects to conversation" do
        post conversation_messages_path(conversation), params: { message: valid_attributes }
        expect(response).to redirect_to(conversation_path(conversation))
        expect(flash[:notice]).to be_present
      end

      context "with AJAX request" do
        it "returns JSON response" do
          post conversation_messages_path(conversation),
               params: { message: valid_attributes },
               headers: { "Accept" => "application/json" }
          expect(response).to have_http_status(:created)
          expect(response.content_type).to include('application/json')
        end
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        {
          content: "" # Invalid: empty content
        }
      end

      it "doesn't create a message" do
        expect {
          post conversation_messages_path(conversation), params: { message: invalid_attributes }
        }.not_to change(Message, :count)
      end

      it "renders conversation show template with errors" do
        post conversation_messages_path(conversation), params: { message: invalid_attributes }
        expect(response.body).to include("can't be blank")
      end

      context "with AJAX request" do
        it "returns unprocessable entity status" do
          post conversation_messages_path(conversation),
               params: { message: invalid_attributes },
               headers: { "Accept" => "application/json" }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when user is not participant in conversation" do
      let(:unauthorized_conversation) { create(:conversation) }

      it "returns 404" do
        expect {
          post conversation_messages_path(unauthorized_conversation), params: { message: valid_attributes }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "PATCH /messages/:id" do
    context "when user is sender of the message" do
      let(:user_message) { create(:message, conversation: conversation, sender: user, recipient: other_user) }

      context "marking as read" do
        before do
          user_message.update!(status: 'unread')
        end

        it "marks message as read" do
          patch message_path(user_message), params: { message: { status: 'read' } }
          expect(user_message.reload.status).to eq('read')
        end

        it "sets read_at timestamp" do
          patch message_path(user_message), params: { message: { status: 'read' } }
          expect(user_message.reload.read_at).to be_present
        end
      end

      context "editing message content (within time limit)" do
        it "updates message content" do
          new_content = "Updated message content"
          patch message_path(user_message), params: { message: { content: new_content } }
          expect(user_message.reload.content).to eq(new_content)
        end

        it "doesn't allow editing after time limit" do
          old_message = create(:message,
            conversation: conversation,
            sender: user,
            recipient: other_user,
            created_at: 1.hour.ago
          )

          patch message_path(old_message), params: { message: { content: "New content" } }
          expect(response).to redirect_to(conversation_path(conversation))
          expect(flash[:alert]).to be_present
        end
      end
    end

    context "when user is recipient of the message" do
      it "allows marking as read" do
        patch message_path(message1), params: { message: { status: 'read' } }
        expect(message1.reload.status).to eq('read')
      end

      it "doesn't allow editing content" do
        original_content = message1.content
        patch message_path(message1), params: { message: { content: "Hacked content" } }
        expect(message1.reload.content).to eq(original_content)
      end
    end
  end

  describe "DELETE /messages/:id" do
    context "when user is sender of the message" do
      let(:user_message) { create(:message, conversation: conversation, sender: user, recipient: other_user) }

      it "soft deletes the message" do
        delete message_path(user_message)
        expect(user_message.reload.status).to eq('deleted')
        expect(response).to redirect_to(conversation_path(conversation))
        expect(flash[:notice]).to be_present
      end

      it "doesn't actually destroy the record" do
        expect {
          delete message_path(user_message)
        }.not_to change(Message, :count)
      end

      context "with AJAX request" do
        it "returns JSON response" do
          delete message_path(user_message), headers: { "Accept" => "application/json" }
          expect(response).to have_http_status(:success)
          expect(response.content_type).to include('application/json')
        end
      end
    end

    context "when user is not sender" do
      it "returns 404" do
        expect {
          delete message_path(message1) # message1 is sent by other_user
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when message is too old to delete" do
      let(:old_message) do
        create(:message,
          conversation: conversation,
          sender: user,
          recipient: other_user,
          created_at: 1.hour.ago
        )
      end

      it "doesn't allow deletion" do
        delete message_path(old_message)
        expect(response).to redirect_to(conversation_path(conversation))
        expect(flash[:alert]).to be_present
        expect(old_message.reload.status).not_to eq('deleted')
      end
    end
  end
end
