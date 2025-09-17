# Rails 8 ActionCable channel for real-time messaging using Solid Cable
class MessagesChannel < ApplicationCable::Channel
  def subscribed
    conversation = find_conversation
    if conversation && authorized_for_conversation?(conversation)
      stream_for conversation
      Rails.logger.info "User #{current_user.id} subscribed to conversation #{conversation.id}"
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    Rails.logger.info "User #{current_user.id} unsubscribed from MessagesChannel"
  end

  # Client calls this to send a new message
  def speak(data)
    conversation = find_conversation
    return unless conversation && authorized_for_conversation?(conversation)

    message = conversation.messages.build(
      content: data['content'],
      sender: current_user,
      recipient: conversation.other_participant(current_user),
      message_type: data['message_type'] || 'text'
    )

    if message.save
      # Broadcast to all subscribers of this conversation
      MessagesChannel.broadcast_to(conversation, {
        action: 'message_created',
        message: message_json(message),
        html: render_message_html(message)
      })
    else
      # Send error back to sender only
      transmit(
        action: 'message_error',
        errors: message.errors.full_messages
      )
    end
  end

  # Client calls this to indicate they're typing
  def typing(data)
    conversation = find_conversation
    return unless conversation && authorized_for_conversation?(conversation)

    # Broadcast typing status to other participants only
    broadcast_to_others(conversation, {
      action: 'user_typing',
      user_id: current_user.id,
      user_name: current_user.profile&.first_name || current_user.email.split('@').first,
      typing: data['typing'] # true or false
    })
  end

  # Client calls this to mark messages as read
  def mark_as_read(data)
    conversation = find_conversation
    return unless conversation && authorized_for_conversation?(conversation)

    if data['message_id']
      # Mark specific message as read
      message = conversation.messages.find_by(id: data['message_id'])
      if message && message.recipient == current_user
        message.mark_as_read!
        broadcast_read_receipt(conversation, message)
      end
    else
      # Mark all messages in conversation as read
      conversation.mark_as_read_for(current_user)
      broadcast_conversation_read(conversation)
    end
  end

  # Client calls this to get their online status
  def update_presence(data)
    conversation = find_conversation
    return unless conversation && authorized_for_conversation?(conversation)

    # Broadcast presence to other participants
    broadcast_to_others(conversation, {
      action: 'user_presence',
      user_id: current_user.id,
      user_name: current_user.profile&.first_name || current_user.email.split('@').first,
      status: data['status'] # 'online', 'away', 'offline'
    })
  end

  private

  def find_conversation
    conversation_id = params[:conversation_id] || params['conversation_id']
    return nil unless conversation_id

    Conversation.find_by(id: conversation_id)
  end

  def authorized_for_conversation?(conversation)
    conversation.participant?(current_user)
  end

  def message_json(message)
    {
      id: message.id,
      content: message.content,
      sender_id: message.sender_id,
      recipient_id: message.recipient_id,
      message_type: message.message_type,
      status: message.status,
      created_at: message.created_at.iso8601,
      sender_name: message.sender.profile&.first_name || message.sender.email.split('@').first
    }
  end

  def render_message_html(message)
    ApplicationController.renderer.render(
      partial: 'messages/message',
      locals: {
        message: message,
        current_user: current_user,
        conversation: message.conversation
      }
    )
  rescue StandardError => e
    Rails.logger.error "Failed to render message HTML: #{e.message}"
    ""
  end

  def broadcast_to_others(conversation, data)
    # Broadcast to all subscribers except the current user
    MessagesChannel.broadcast_to(conversation, data.merge(
      sender_id: current_user.id
    ))
  end

  def broadcast_read_receipt(conversation, message)
    MessagesChannel.broadcast_to(conversation, {
      action: 'message_read',
      message_id: message.id,
      reader_id: current_user.id,
      read_at: message.read_at&.iso8601
    })
  end

  def broadcast_conversation_read(conversation)
    MessagesChannel.broadcast_to(conversation, {
      action: 'conversation_read',
      reader_id: current_user.id,
      read_at: Time.current.iso8601
    })
  end
end