import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="property-card"
export default class extends Controller {
  static targets = ["card", "image", "details"]

  connect() {
    this.setupHoverAnimation()
  }

  setupHoverAnimation() {
    if (!this.hasCardTarget) return

    // Set initial state
    this.cardTarget.style.transition = "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)"
    this.cardTarget.style.transform = "translateY(0px)"

    if (this.hasImageTarget) {
      this.imageTarget.style.transition = "transform 0.3s cubic-bezier(0.4, 0, 0.2, 1)"
    }
  }

  mouseEnter() {
    if (!this.hasCardTarget) return

    // Lift the card and scale the image slightly
    this.cardTarget.style.transform = "translateY(-8px)"
    this.cardTarget.style.boxShadow = "0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)"

    if (this.hasImageTarget) {
      this.imageTarget.style.transform = "scale(1.05)"
    }

    // Add animation to details if present
    if (this.hasDetailsTarget) {
      this.detailsTarget.style.transition = "all 0.3s ease"
      this.detailsTarget.style.transform = "translateY(-2px)"
    }
  }

  mouseLeave() {
    if (!this.hasCardTarget) return

    // Return to original state
    this.cardTarget.style.transform = "translateY(0px)"
    this.cardTarget.style.boxShadow = "0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)"

    if (this.hasImageTarget) {
      this.imageTarget.style.transform = "scale(1)"
    }

    if (this.hasDetailsTarget) {
      this.detailsTarget.style.transform = "translateY(0px)"
    }
  }

  // Favorite animation
  toggleFavorite(event) {
    event.preventDefault()
    event.stopPropagation()

    const button = event.currentTarget
    const icon = button.querySelector('svg')

    // Add pulse animation
    button.style.transform = "scale(1.2)"
    button.style.transition = "transform 0.2s ease"

    setTimeout(() => {
      button.style.transform = "scale(1)"
    }, 200)

    // Toggle heart color
    if (icon) {
      icon.style.transition = "all 0.3s ease"
      if (icon.classList.contains('text-red-500')) {
        icon.classList.remove('text-red-500', 'fill-current')
        icon.classList.add('text-gray-400')
      } else {
        icon.classList.remove('text-gray-400')
        icon.classList.add('text-red-500', 'fill-current')
      }
    }

    // Add floating heart animation
    this.createFloatingHeart(button)
  }

  createFloatingHeart(element) {
    const heart = document.createElement('div')
    heart.innerHTML = '❤️'
    heart.style.position = 'absolute'
    heart.style.fontSize = '20px'
    heart.style.pointerEvents = 'none'
    heart.style.zIndex = '1000'
    heart.style.animation = 'float-heart 1s ease-out forwards'

    const rect = element.getBoundingClientRect()
    heart.style.left = `${rect.left + rect.width / 2}px`
    heart.style.top = `${rect.top}px`

    document.body.appendChild(heart)

    // Remove heart after animation
    setTimeout(() => {
      if (heart.parentNode) {
        heart.parentNode.removeChild(heart)
      }
    }, 1000)
  }
}