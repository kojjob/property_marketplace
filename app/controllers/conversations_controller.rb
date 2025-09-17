class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation, only: [ :show, :update, :destroy ]

  # GET /conversations
  def index
    @conversations = current_user.conversations
                                .active
                                .with_messages
                                .recent
                                .includes(:participant1, :participant2, :messages)
  end

  # GET /conversations/:id
  def show
    @messages = @conversation.messages
                            .not_deleted
                            .includes(:sender, :recipient, images_attachments: :blob, documents_attachments: :blob)
                            .order(:created_at)

    # Mark messages as read for current user
    @conversation.mark_as_read_for(current_user)

    # Build a new message for the form
    @message = @conversation.messages.build(
      sender: current_user,
      recipient: @conversation.other_participant(current_user)
    )
  end

  # POST /conversations
  def create
    @recipient = User.find(params[:recipient_id])

    if @recipient == current_user
      redirect_to conversations_path, alert: "You cannot start a conversation with yourself."
      return
    end

    unless current_user.can_message?(@recipient)
      redirect_to conversations_path, alert: "You cannot message this user."
      return
    end

    @conversation = Conversation.find_or_create_between(current_user, @recipient)

    if @conversation
      redirect_to conversation_path(@conversation)
    else
      redirect_to conversations_path, alert: "Unable to create conversation."
    end
  end

  # PATCH /conversations/:id
  def update
    if conversation_params[:archived] == "true" || conversation_params[:archived] == true
      @conversation.archive!
      flash[:notice] = "Conversation archived."
    elsif conversation_params[:archived] == "false" || conversation_params[:archived] == false
      @conversation.unarchive!
      flash[:notice] = "Conversation unarchived."
    end

    redirect_to conversations_path
  end

  # DELETE /conversations/:id
  def destroy
    @conversation.archive!
    flash[:notice] = "Conversation archived."
    redirect_to conversations_path
  end

  private

  def set_conversation
    @conversation = current_user.conversations.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    raise ActiveRecord::RecordNotFound, "Conversation not found or you don't have access"
  end

  def conversation_params
    params.require(:conversation).permit(:archived)
  end
end
