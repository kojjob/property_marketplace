import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

// Connects to data-controller="messages"
export default class extends Controller {
  static targets = [
    "messagesContainer",
    "messageForm",
    "messageInput",
    "sendButton",
    "typingIndicator",
    "typingUser",
    "userStatus"
  ]

  static values = {
    conversationId: Number,
    currentUserId: Number
  }

  connect() {
    console.log("Messages controller connected for conversation", this.conversationIdValue)

    this.setupActionCable()
    this.setupAutoResize()
    this.scrollToBottom()
    this.markMessagesAsRead()

    // Set up typing detection
    this.typingTimer = null
    this.isTyping = false
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }

    if (this.typingTimer) {
      clearTimeout(this.typingTimer)
    }
  }

  setupActionCable() {
    this.cable = createConsumer()

    this.subscription = this.cable.subscriptions.create(
      {
        channel: "MessagesChannel",
        conversation_id: this.conversationIdValue
      },
      {
        connected: () => {
          console.log("Connected to MessagesChannel for conversation", this.conversationIdValue)
          this.updateUserStatus("online")
        },

        disconnected: () => {
          console.log("Disconnected from MessagesChannel")
          this.updateUserStatus("offline")
        },

        received: (data) => {
          console.log("Received data:", data)
          this.handleReceivedData(data)
        },

        speak: (content, messageType = 'text') => {
          this.subscription.perform('speak', {
            content: content,
            message_type: messageType
          })
        },

        typing: (isTyping) => {
          this.subscription.perform('typing', { typing: isTyping })
        },

        markAsRead: (messageId = null) => {
          this.subscription.perform('mark_as_read', { message_id: messageId })
        },

        updatePresence: (status) => {
          this.subscription.perform('update_presence', { status: status })
        }
      }
    )
  }

  handleReceivedData(data) {
    switch (data.action) {
      case 'message_created':
        this.handleNewMessage(data)
        break
      case 'message_read':
        this.handleMessageRead(data)
        break
      case 'conversation_read':
        this.handleConversationRead(data)
        break
      case 'user_typing':
        this.handleUserTyping(data)
        break
      case 'user_presence':
        this.handleUserPresence(data)
        break
      case 'message_error':
        this.handleMessageError(data)
        break
    }
  }

  handleNewMessage(data) {
    // Insert the new message HTML for all messages
    if (data.html) {
      this.messagesContainerTarget.insertAdjacentHTML('beforeend', data.html)
      this.scrollToBottom()

      // Only mark as read if it's not from current user
      if (data.message.sender_id !== this.currentUserIdValue) {
        this.markMessagesAsRead()
      }
    }

    // Hide typing indicator since user sent message
    this.hideTypingIndicator()
  }

  handleMessageRead(data) {
    if (data.reader_id !== this.currentUserIdValue) {
      // Update read status indicator for our messages
      const messageElement = this.messagesContainerTarget.querySelector(`[data-message-id="${data.message_id}"]`)
      if (messageElement) {
        const statusElement = messageElement.querySelector('[title="Sent"]')
        if (statusElement) {
          statusElement.innerHTML = '✓✓'
          statusElement.title = 'Read'
          statusElement.className = statusElement.className.replace('text-gray-400', 'text-indigo-500')
        }
      }
    }
  }

  handleConversationRead(data) {
    if (data.reader_id !== this.currentUserIdValue) {
      // Mark all our messages as read
      const ourMessages = this.messagesContainerTarget.querySelectorAll(`[data-message-sender="${this.currentUserIdValue}"]`)
      ourMessages.forEach(messageElement => {
        const statusElement = messageElement.querySelector('[title="Sent"]')
        if (statusElement) {
          statusElement.innerHTML = '✓✓'
          statusElement.title = 'Read'
          statusElement.className = statusElement.className.replace('text-gray-400', 'text-indigo-500')
        }
      })
    }
  }

  handleUserTyping(data) {
    if (data.user_id !== this.currentUserIdValue) {
      if (data.typing) {
        this.showTypingIndicator(data.user_name)
      } else {
        this.hideTypingIndicator()
      }
    }
  }

  handleUserPresence(data) {
    if (data.user_id !== this.currentUserIdValue && this.hasUserStatusTarget) {
      const statusText = data.status === 'online' ? 'Online' : 'Last seen recently'
      this.userStatusTarget.textContent = statusText
      this.userStatusTarget.className = data.status === 'online' ? 'text-green-500' : 'text-gray-500'
    }
  }

  handleMessageError(data) {
    console.error("Message error:", data.errors)
    alert("Failed to send message: " + data.errors.join(", "))
    this.enableForm()
  }

  sendMessage(event) {
    event.preventDefault()

    const content = this.messageInputTarget.value.trim()
    if (!content) return

    this.disableForm()

    // Store message content for immediate display
    const messageContent = content

    // Clear the form immediately for better UX
    this.messageInputTarget.value = ''
    this.adjustTextareaHeight()

    // Send via ActionCable for real-time delivery
    if (this.subscription) {
      this.subscription.speak(messageContent)
    }

    // Also submit the form for persistence and fallback
    const formData = new FormData(this.messageFormTarget)
    // Re-add content since we cleared the input
    formData.set('message[content]', messageContent)

    fetch(this.messageFormTarget.action, {
      method: 'POST',
      body: formData,
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      }
    })
    .then(response => {
      if (response.ok) {
        return response.json()
      } else {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
      }
    })
    .then(data => {
      if (data.errors) {
        // If there's an error, restore the message content
        this.messageInputTarget.value = messageContent
        this.adjustTextareaHeight()
        this.handleMessageError(data)
      } else if (data.success) {
        // Success - form is already cleared
        this.enableForm()
        console.log("Message sent successfully:", data.message)
      } else {
        // Unexpected response format
        this.messageInputTarget.value = messageContent
        this.adjustTextareaHeight()
        console.error("Unexpected response:", data)
        this.enableForm()
      }
    })
    .catch(error => {
      console.error('Error sending message:', error)
      // Restore the message content on error
      this.messageInputTarget.value = messageContent
      this.adjustTextareaHeight()
      alert('Failed to send message. Please try again.')
      this.enableForm()
    })
  }

  handleTyping(event) {
    const content = this.messageInputTarget.value.trim()

    if (content.length > 0 && !this.isTyping) {
      // Start typing
      this.isTyping = true
      if (this.subscription) {
        this.subscription.typing(true)
      }
    }

    // Clear previous timer
    if (this.typingTimer) {
      clearTimeout(this.typingTimer)
    }

    // Set new timer to stop typing indicator
    this.typingTimer = setTimeout(() => {
      if (this.isTyping) {
        this.isTyping = false
        if (this.subscription) {
          this.subscription.typing(false)
        }
      }
    }, 2000) // Stop typing indicator after 2 seconds of inactivity
  }

  handleKeydown(event) {
    // Send message on Enter (but not Shift+Enter)
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault()
      this.sendMessage(event)
    }
  }

  setupAutoResize() {
    this.messageInputTarget.addEventListener('input', () => {
      this.adjustTextareaHeight()
    })
  }

  adjustTextareaHeight() {
    const textarea = this.messageInputTarget
    textarea.style.height = 'auto'
    textarea.style.height = Math.min(textarea.scrollHeight, 100) + 'px'
  }

  scrollToBottom() {
    requestAnimationFrame(() => {
      this.messagesContainerTarget.scrollTop = this.messagesContainerTarget.scrollHeight
    })
  }

  markMessagesAsRead() {
    // Mark all messages as read when viewing the conversation
    if (this.subscription) {
      this.subscription.markAsRead()
    }
  }

  showTypingIndicator(userName) {
    if (this.hasTypingIndicatorTarget && this.hasTypingUserTarget) {
      this.typingUserTarget.textContent = `${userName} is typing...`
      this.typingIndicatorTarget.classList.remove('hidden')
      this.scrollToBottom()
    }
  }

  hideTypingIndicator() {
    if (this.hasTypingIndicatorTarget) {
      this.typingIndicatorTarget.classList.add('hidden')
    }
  }

  updateUserStatus(status) {
    if (this.subscription) {
      this.subscription.updatePresence(status)
    }
  }

  disableForm() {
    this.sendButtonTarget.disabled = true
    this.sendButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
    this.sendButtonTarget.textContent = 'Sending...'
    this.messageInputTarget.disabled = true
  }

  enableForm() {
    this.sendButtonTarget.disabled = false
    this.sendButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
    this.sendButtonTarget.textContent = 'Send'
    this.messageInputTarget.disabled = false
    this.messageInputTarget.focus()
  }

  editMessage(event) {
    event.preventDefault()
    const messageId = event.target.dataset.messageId
    // Implement edit functionality
    console.log("Edit message", messageId)
    // This would open an inline edit form
  }
}