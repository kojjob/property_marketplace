class MessagesController < ApplicationController
  before_action :set_conversation, only: [ :index, :create ]
  before_action :set_message, only: [ :show, :update, :destroy ]

  # Time limit for editing/deleting messages
  EDIT_TIME_LIMIT = 15.minutes

  # GET /messages
  # GET /conversations/:conversation_id/messages
  def index
    if @conversation
      @messages = @conversation.messages
                              .not_deleted
                              .includes(:sender, :recipient, images_attachments: :blob, documents_attachments: :blob)
                              .order(:created_at)
    else
      @messages = current_user.received_messages
                              .not_deleted
                              .includes(:conversation, :sender, images_attachments: :blob, documents_attachments: :blob)
                              .recent
                              .order(created_at: :desc)
    end

    respond_to do |format|
      format.html
      format.json { render json: @messages }
    end
  end

  # GET /messages/:id
  def show
    # Mark as read if current user is the recipient
    if @message.recipient == current_user && @message.unread?
      @message.mark_as_read!
    end

    respond_to do |format|
      format.html
      format.json { render json: @message }
    end
  end

  # POST /messages
  # POST /conversations/:conversation_id/messages
  def create
    @message = @conversation.messages.build(message_params)
    @message.sender = current_user
    @message.recipient = @conversation.other_participant(current_user)

    if @message.save
      respond_to do |format|
        format.html do
          flash[:notice] = "Message sent successfully."
          redirect_to conversation_path(@conversation)
        end
        format.json {
          render json: {
            success: true,
            message: {
              id: @message.id,
              content: @message.content,
              created_at: @message.created_at.iso8601
            }
          }, status: :created
        }
      end
    else
      respond_to do |format|
        format.html do
          # Re-load data for the conversation show page
          @messages = @conversation.messages
                                  .not_deleted
                                  .includes(:sender, :recipient, images_attachments: :blob, documents_attachments: :blob)
                                  .order(:created_at)
          render "conversations/show"
        end
        format.json { render json: { errors: @message.errors }, status: :unprocessable_content }
      end
    end
  end

  # PATCH /messages/:id
  def update
    # Check if user can edit this message
    if @message.sender != current_user
      respond_to do |format|
        format.html do
          flash[:alert] = "You can only edit your own messages."
          redirect_to conversation_path(@message.conversation)
        end
        format.json { render json: { error: "Unauthorized" }, status: :forbidden }
      end
      return
    end

    # Handle status updates (marking as read, archiving, etc.)
    if message_params[:status].present?
      case message_params[:status]
      when "read"
        @message.mark_as_read!
      when "archived"
        @message.archive!
      when "unread"
        @message.mark_as_unread!
      end
    end

    # Handle content updates (only if within time limit)
    if message_params[:content].present?
      unless editable?(@message, current_user)
        respond_to do |format|
          format.html do
            flash[:alert] = "Messages can only be edited within #{EDIT_TIME_LIMIT.inspect} of sending."
            redirect_to conversation_path(@message.conversation)
          end
          format.json { render json: { error: "Edit time limit exceeded" }, status: :unprocessable_content }
        end
        return
      end

      @message.content = message_params[:content]
    end

    if @message.save
      respond_to do |format|
        format.html { redirect_back_or_to(conversation_path(@message.conversation)) }
        format.json { render json: @message }
      end
    else
      respond_to do |format|
        format.html do
          flash[:alert] = "Unable to update message."
          redirect_to conversation_path(@message.conversation)
        end
        format.json { render json: { errors: @message.errors }, status: :unprocessable_content }
      end
    end
  end

  # DELETE /messages/:id
  def destroy
    unless deletable?(@message, current_user)
      respond_to do |format|
        format.html do
          flash[:alert] = "You can only delete your own messages within #{EDIT_TIME_LIMIT.inspect} of sending."
          redirect_to conversation_path(@message.conversation)
        end
        format.json { render json: { error: "Cannot delete message" }, status: :forbidden }
      end
      return
    end

    @message.soft_delete!

    respond_to do |format|
      format.html do
        flash[:notice] = "Message deleted."
        redirect_to conversation_path(@message.conversation)
      end
      format.json { render json: { status: "deleted" } }
    end
  end

  private

  def set_conversation
    if params[:conversation_id]
      @conversation = current_user.conversations.find(params[:conversation_id])
    end
  rescue ActiveRecord::RecordNotFound
    raise ActiveRecord::RecordNotFound, "Conversation not found or you don't have access"
  end

  def set_message
    # Find message where current user is either sender or recipient
    @message = Message.joins(:conversation)
                     .where(id: params[:id])
                     .where(
                       "conversations.participant1_id = ? OR conversations.participant2_id = ?",
                       current_user.id, current_user.id
                     )
                     .first!
  rescue ActiveRecord::RecordNotFound
    raise ActiveRecord::RecordNotFound, "Message not found or you don't have access"
  end

  def message_params
    params.require(:message).permit(
      :content, :status, :regarding_type, :regarding_id, :conversation_id,
      images: [], documents: []
    )
  end

  def editable?(message, user)
    return false unless message.sender == user
    return false if message.created_at < EDIT_TIME_LIMIT.ago
    true
  end

  def deletable?(message, user)
    return false unless message.sender == user
    return false if message.created_at < EDIT_TIME_LIMIT.ago
    true
  end

  def redirect_back_or_to(default_url)
    redirect_to(request.referer || default_url)
  end
end
