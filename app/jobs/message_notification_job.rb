# Job to handle message notifications using Rails 8 Solid Queue
class MessageNotificationJob < ApplicationJob
  queue_as :notifications
  queue_with_priority 5 # Higher priority for real-time notifications

  # Retry on network issues, but not on permanent failures
  retry_on ActiveRecord::ConnectionTimeoutError, wait: :exponentially_longer, attempts: 5
  retry_on Timeout::Error, wait: :exponentially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(message)
    return unless message.is_a?(Message)
    return if message.message_type == "system_message"
    return unless message.recipient

    # Send email notification if user has email notifications enabled
    send_email_notification(message) if should_send_email?(message)

    # Send push notification if user has them enabled
    send_push_notification(message) if should_send_push?(message)

    # Broadcast to ActionCable for real-time updates
    broadcast_message(message)

    # Log the notification for analytics
    log_notification(message)
  end

  private

  def should_send_email?(message)
    recipient = message.recipient
    return false unless recipient.confirmed? # Only send to confirmed users

    # Check user preferences (would be stored in user profile or settings)
    # For now, we'll assume users want email notifications
    # In a real app, you'd check: recipient.profile&.email_notifications?
    true
  end

  def should_send_push?(message)
    recipient = message.recipient
    return false unless recipient.confirmed?

    # Check if user has push notifications enabled
    # For now, we'll assume they do
    # In a real app: recipient.profile&.push_notifications?
    false # Disabled for now, would need push service setup
  end

  def send_email_notification(message)
    # Use Postmark for email delivery (configured in the app)
    UserMailer.new_message_notification(message).deliver_now
  rescue StandardError => e
    # Log error but don't fail the job
    Rails.logger.error "Failed to send email for message #{message.id}: #{e.message}"
  end

  def send_push_notification(message)
    # This would integrate with a push notification service
    # Like Firebase Cloud Messaging, Apple Push Notifications, etc.
    # For now, just log that we would send one
    Rails.logger.info "Would send push notification for message #{message.id}"
  end

  def broadcast_message(message)
    # Broadcast to ActionCable for real-time updates
    MessagesChannel.broadcast_to(
      message.conversation,
      {
        action: "message_created",
        message: message,
        html: render_message_html(message)
      }
    )
  rescue StandardError => e
    Rails.logger.error "Failed to broadcast message #{message.id}: #{e.message}"
  end

  def render_message_html(message)
    # Render the message HTML for real-time insertion
    ApplicationController.renderer.render(
      partial: "messages/message",
      locals: { message: message, current_user: message.recipient }
    )
  rescue StandardError => e
    Rails.logger.error "Failed to render message HTML for #{message.id}: #{e.message}"
    ""
  end

  def log_notification(message)
    # Log notification for analytics (could use Ahoy or custom analytics)
    Rails.logger.info "Notification sent for message #{message.id} to user #{message.recipient.id}"
  end
end
