import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="property-detail"
export default class extends Controller {
  static targets = ["shareButton", "printButton", "favoriteButton"]

  connect() {
    this.setupScrollAnimations()
    this.setupStickyElements()
    console.log("Property detail controller connected")
  }

  setupScrollAnimations() {
    // Add scroll-based animations for elements coming into view
    const observerOptions = {
      threshold: 0.1,
      rootMargin: "0px 0px -50px 0px"
    }

    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('animate-fadeIn')
        }
      })
    }, observerOptions)

    // Observe cards and sections
    const animatedElements = this.element.querySelectorAll('.card')
    animatedElements.forEach(el => observer.observe(el))
  }

  setupStickyElements() {
    // Make the agent contact card sticky on larger screens
    const agentCard = this.element.querySelector('.space-y-6 > .card')
    if (agentCard && window.innerWidth >= 1024) {
      agentCard.style.position = 'sticky'
      agentCard.style.top = '2rem'
    }
  }

  // Share functionality
  shareProperty(event) {
    event.preventDefault()

    if (navigator.share) {
      navigator.share({
        title: document.title,
        text: 'Check out this amazing property!',
        url: window.location.href
      })
    } else {
      // Fallback: copy to clipboard
      navigator.clipboard.writeText(window.location.href).then(() => {
        this.showNotification('Link copied to clipboard!')
      })
    }
  }

  // Print functionality
  printProperty(event) {
    event.preventDefault()
    window.print()
  }

  // Report property functionality
  reportProperty(event) {
    event.preventDefault()
    // Open report modal or form
    this.showNotification('Report functionality coming soon')
  }

  // Utility methods
  showNotification(message) {
    // Create a temporary notification
    const notification = document.createElement('div')
    notification.className = 'alert alert-success fixed top-4 right-4 w-auto z-50'
    notification.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      <span>${message}</span>
    `

    document.body.appendChild(notification)

    // Animate in
    notification.style.transform = 'translateX(100%)'
    notification.style.transition = 'transform 0.3s ease'

    requestAnimationFrame(() => {
      notification.style.transform = 'translateX(0)'
    })

    // Remove after 3 seconds
    setTimeout(() => {
      notification.style.transform = 'translateX(100%)'
      setTimeout(() => {
        document.body.removeChild(notification)
      }, 300)
    }, 3000)
  }

  // Scroll to section
  scrollToSection(event) {
    event.preventDefault()
    const targetId = event.currentTarget.dataset.target
    const targetElement = document.getElementById(targetId)

    if (targetElement) {
      targetElement.scrollIntoView({
        behavior: 'smooth',
        block: 'start'
      })
    }
  }

  // Analytics tracking (future enhancement)
  trackInteraction(event) {
    const action = event.currentTarget.dataset.track
    console.log(`Tracking: ${action}`)
    // Implement analytics tracking here
  }

  disconnect() {
    console.log("Property detail controller disconnected")
  }
}