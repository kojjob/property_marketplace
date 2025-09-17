class MessageService < ApplicationService
  def initialize(sender, recipient, message_params)
    @sender = sender
    @recipient = recipient
    @message_params = message_params
  end

  def call
    ActiveRecord::Base.transaction do
      find_or_create_conversation
      create_message
      update_conversation_metadata
      notify_recipient
      success(message: @message, conversation: @conversation)
    end
  rescue ActiveRecord::RecordInvalid => e
    failure(e.message)
  rescue StandardError => e
    failure(e.message)
  end

  private

  attr_reader :sender, :recipient, :message_params

  def find_or_create_conversation
    @conversation = Conversation.find_or_create_between(sender, recipient)
    raise StandardError, "Cannot create conversation with yourself" unless @conversation
  end

  def create_message
    @message = Message.create!(
      sender: sender,
      recipient: recipient,
      conversation: @conversation,
      content: message_params[:content],
      message_type: message_params[:message_type] || "text",
      regarding: message_params[:regarding]  # Optional polymorphic association
    )

    # Handle attachments if provided
    attach_files if message_params[:attachments].present?
  end

  def attach_files
    message_params[:attachments].each do |attachment|
      if attachment[:type] == "image"
        @message.images.attach(attachment[:file])
      elsif attachment[:type] == "document"
        @message.documents.attach(attachment[:file])
      end
    end
  end

  def update_conversation_metadata
    @conversation.update!(
      last_message_at: @message.created_at
    )
  end

  def notify_recipient
    # Real-time notification via ActionCable
    broadcast_message if defined?(ActionCable)

    # Email notification if recipient has been inactive
    queue_email_notification if should_send_email?
  end

  def broadcast_message
    ActionCable.server.broadcast(
      "conversation_#{@conversation.id}",
      {
        message: render_message,
        conversation_id: @conversation.id
      }
    )
  end

  def render_message
    # In a real app, this would render the message partial
    {
      id: @message.id,
      content: @message.content,
      sender_id: @message.sender_id,
      created_at: @message.created_at,
      status: @message.status
    }
  end

  def should_send_email?
    # Send email if recipient hasn't been active in last hour
    last_activity = recipient.sessions.where("updated_at > ?", 1.hour.ago).exists?
    !last_activity
  end

  def queue_email_notification
    MessageNotificationJob.perform_later(@message) if defined?(MessageNotificationJob)
  end
end
