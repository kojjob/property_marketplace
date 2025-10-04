import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="property-contact"
export default class extends Controller {
  static targets = ["modal", "form", "callModal", "tourModal"]

  connect() {
    console.log("Property contact controller connected")
  }

  // Handle Contact Agent button click
  contactAgent(event) {
    event.preventDefault()
    this.showContactModal()
  }

  // Handle Call Now button click
  callNow(event) {
    event.preventDefault()
    const agentPhone = this.data.get("phone") || "+1 (555) 123-4567"

    // Try to initiate phone call on mobile devices
    if (this.isMobile()) {
      window.location.href = `tel:${agentPhone}`
    } else {
      // Show call information modal on desktop
      this.showCallModal(agentPhone)
    }
  }

  // Handle Schedule Tour button click
  scheduleTour(event) {
    event.preventDefault()
    this.showTourModal()
  }

  // Show contact form modal
  showContactModal() {
    const modal = this.createModal(`
      <div class="bg-white rounded-xl p-6 max-w-md w-full mx-4">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-xl font-bold text-gray-900">Contact Agent</h3>
          <button class="text-gray-400 hover:text-gray-600" data-action="click->property-contact#closeModal">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>

        <form data-action="submit->property-contact#submitContact" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Your Name</label>
            <input type="text" name="name" required class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
            <input type="email" name="email" required class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Phone</label>
            <input type="tel" name="phone" class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Message</label>
            <textarea name="message" rows="3" class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500" placeholder="I'm interested in this property..."></textarea>
          </div>

          <div class="flex gap-3 pt-2">
            <button type="button" data-action="click->property-contact#closeModal" class="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50">
              Cancel
            </button>
            <button type="submit" class="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
              Send Message
            </button>
          </div>
        </form>
      </div>
    `)

    document.body.appendChild(modal)
  }

  // Show call information modal
  showCallModal(phone) {
    const modal = this.createModal(`
      <div class="bg-white rounded-xl p-6 max-w-md w-full mx-4 text-center">
        <div class="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"></path>
          </svg>
        </div>

        <h3 class="text-xl font-bold text-gray-900 mb-2">Call Agent</h3>
        <p class="text-gray-600 mb-4">Ready to speak with our agent?</p>
        <p class="text-2xl font-bold text-blue-600 mb-6">${phone}</p>

        <div class="flex gap-3">
          <button data-action="click->property-contact#closeModal" class="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50">
            Cancel
          </button>
          <a href="tel:${phone}" class="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 text-center">
            Call Now
          </a>
        </div>
      </div>
    `)

    document.body.appendChild(modal)
  }

  // Show tour scheduling modal
  showTourModal() {
    const modal = this.createModal(`
      <div class="bg-white rounded-xl p-6 max-w-md w-full mx-4">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-xl font-bold text-gray-900">Schedule a Tour</h3>
          <button class="text-gray-400 hover:text-gray-600" data-action="click->property-contact#closeModal">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>

        <form data-action="submit->property-contact#submitTourRequest" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Your Name</label>
            <input type="text" name="name" required class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
            <input type="email" name="email" required class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Phone</label>
            <input type="tel" name="phone" required class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Preferred Date</label>
            <input type="date" name="preferred_date" required class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500" min="${this.getTomorrowDate()}">
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Preferred Time</label>
            <select name="preferred_time" required class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
              <option value="">Select time</option>
              <option value="09:00">9:00 AM</option>
              <option value="10:00">10:00 AM</option>
              <option value="11:00">11:00 AM</option>
              <option value="13:00">1:00 PM</option>
              <option value="14:00">2:00 PM</option>
              <option value="15:00">3:00 PM</option>
              <option value="16:00">4:00 PM</option>
              <option value="17:00">5:00 PM</option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Special Requests</label>
            <textarea name="message" rows="2" class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500" placeholder="Any specific areas you'd like to focus on?"></textarea>
          </div>

          <div class="flex gap-3 pt-2">
            <button type="button" data-action="click->property-contact#closeModal" class="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50">
              Cancel
            </button>
            <button type="submit" class="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
              Schedule Tour
            </button>
          </div>
        </form>
      </div>
    `)

    document.body.appendChild(modal)
  }

  // Submit contact form
  submitContact(event) {
    event.preventDefault()
    const formData = new FormData(event.target)

    // Show success message
    this.showSuccessModal("Thank you for your interest!", "We'll get back to you within 24 hours.")
  }

  // Submit tour request
  submitTourRequest(event) {
    event.preventDefault()
    const formData = new FormData(event.target)

    // Show success message
    this.showSuccessModal("Tour Scheduled!", "We'll confirm your tour appointment via email and phone.")
  }

  // Show success modal
  showSuccessModal(title, message) {
    this.closeModal()

    const modal = this.createModal(`
      <div class="bg-white rounded-xl p-6 max-w-md w-full mx-4 text-center">
        <div class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
          </svg>
        </div>

        <h3 class="text-xl font-bold text-gray-900 mb-2">${title}</h3>
        <p class="text-gray-600 mb-6">${message}</p>

        <button data-action="click->property-contact#closeModal" class="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
          Close
        </button>
      </div>
    `)

    document.body.appendChild(modal)
  }

  // Create modal backdrop
  createModal(content) {
    const modal = document.createElement('div')
    modal.className = 'fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4'
    modal.dataset.controller = 'property-contact'
    modal.innerHTML = content

    // Close on backdrop click
    modal.addEventListener('click', (event) => {
      if (event.target === modal) {
        this.closeModal()
      }
    })

    // Close on Escape key
    document.addEventListener('keydown', this.escapeHandler = (event) => {
      if (event.key === 'Escape') {
        this.closeModal()
      }
    })

    return modal
  }

  // Close modal
  closeModal() {
    const modals = document.querySelectorAll('.fixed.inset-0.bg-black')
    modals.forEach(modal => modal.remove())

    if (this.escapeHandler) {
      document.removeEventListener('keydown', this.escapeHandler)
      this.escapeHandler = null
    }
  }

  // Utility functions
  isMobile() {
    return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
  }

  getTomorrowDate() {
    const tomorrow = new Date()
    tomorrow.setDate(tomorrow.getDate() + 1)
    return tomorrow.toISOString().split('T')[0]
  }

  disconnect() {
    this.closeModal()
  }
}