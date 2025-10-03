require 'rails_helper'

RSpec.describe "Conversations", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:third_user) { create(:user) }
  let!(:conversation1) { create(:conversation, participant1: user, participant2: other_user) }
  let!(:conversation2) { create(:conversation, participant1: user, participant2: third_user) }

  # Sign in user for testing core functionality
  before do
    sign_in user
  end

  describe "GET /conversations" do
    context "when user is authenticated" do
      before do
        # Create some messages to make conversations active
        create(:message, conversation: conversation1, sender: other_user, recipient: user)
        create(:message, conversation: conversation2, sender: third_user, recipient: user)
      end

      it "returns successful response" do
        get conversations_path
        expect(response).to have_http_status(:success)
      end

      it "displays user's conversations" do
        get conversations_path
        expect(response.body).to include(other_user.email.split('@').first)
        expect(response.body).to include(third_user.email.split('@').first)
      end
    end

    context "when user is not authenticated" do
      before do
        sign_out user
      end

      it "redirects to sign in page" do
        get conversations_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /conversations/:id" do
    let!(:messages) { create_list(:message, 3, conversation: conversation1, sender: other_user, recipient: user) }

    context "when user is participant in conversation" do
      it "returns successful response" do
        get conversation_path(conversation1)
        expect(response).to have_http_status(:success)
      end

      it "displays conversation messages" do
        get conversation_path(conversation1)
        messages.each do |message|
          expect(response.body).to include(message.content)
        end
      end

      it "marks messages as read for current user" do
        expect(conversation1.unread_count_for(user)).to be > 0

        get conversation_path(conversation1)

        expect(conversation1.reload.unread_count_for(user)).to eq(0)
      end
    end

    context "when user is not a participant" do
      let(:unauthorized_conversation) { create(:conversation) }

      it "returns 404" do
        expect {
          get conversation_path(unauthorized_conversation)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "POST /conversations" do
    context "when creating conversation with valid user" do
      context "when conversation doesn't exist" do
        it "creates a new conversation" do
          expect {
            post conversations_path, params: { recipient_id: third_user.id }
          }.to change(Conversation, :count).by(1)
        end

        it "redirects to the conversation" do
          post conversations_path, params: { recipient_id: third_user.id }
          expect(response).to redirect_to(conversation_path(Conversation.last))
        end

        it "creates conversation with correct participants" do
          post conversations_path, params: { recipient_id: third_user.id }
          conversation = Conversation.last
          expect([ conversation.participant1, conversation.participant2 ]).to contain_exactly(user, third_user)
        end
      end

      context "when conversation already exists" do
        it "doesn't create a new conversation" do
          expect {
            post conversations_path, params: { recipient_id: other_user.id }
          }.not_to change(Conversation, :count)
        end

        it "redirects to existing conversation" do
          post conversations_path, params: { recipient_id: other_user.id }
          expect(response).to redirect_to(conversation_path(conversation1))
        end
      end
    end

    context "when creating conversation with invalid parameters" do
      it "raises error when recipient_id is missing" do
        expect {
          post conversations_path, params: {}
        }.to raise_error(ActionController::ParameterMissing)
      end

      it "raises error when recipient doesn't exist" do
        expect {
          post conversations_path, params: { recipient_id: 999999 }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "redirects with error when trying to message self" do
        post conversations_path, params: { recipient_id: user.id }
        expect(response).to redirect_to(conversations_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "PATCH /conversations/:id" do
    context "when archiving conversation" do
      it "archives the conversation" do
        patch conversation_path(conversation1), params: { conversation: { archived: true } }
        expect(conversation1.reload).to be_archived
        expect(response).to redirect_to(conversations_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "when unarchiving conversation" do
      before do
        conversation1.archive!
      end

      it "unarchives the conversation" do
        patch conversation_path(conversation1), params: { conversation: { archived: false } }
        expect(conversation1.reload).not_to be_archived
        expect(response).to redirect_to(conversations_path)
      end
    end
  end

  describe "DELETE /conversations/:id" do
    it "archives the conversation instead of deleting" do
      expect {
        delete conversation_path(conversation1)
      }.not_to change(Conversation, :count)

      expect(conversation1.reload).to be_archived
      expect(response).to redirect_to(conversations_path)
      expect(flash[:notice]).to be_present
    end
  end
end
