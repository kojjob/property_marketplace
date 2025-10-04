import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.isOpen = false
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.classList.remove('hidden')
    this.isOpen = true

    // Close dropdown when clicking outside
    document.addEventListener('click', this.closeOnOutsideClick.bind(this))
  }

  close() {
    this.menuTarget.classList.add('hidden')
    this.isOpen = false

    // Remove event listener
    document.removeEventListener('click', this.closeOnOutsideClick.bind(this))
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  disconnect() {
    if (this.isOpen) {
      document.removeEventListener('click', this.closeOnOutsideClick.bind(this))
    }
  }
}