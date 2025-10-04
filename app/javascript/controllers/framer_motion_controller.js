import { Controller } from "@hotwired/stimulus"
import { motion } from "framer-motion"

// Connects to data-controller="framer-motion"
export default class extends Controller {
  static targets = ["animatedElement", "card", "modal", "fade", "slide", "scale"]
  static values = {
    animation: String,
    duration: Number,
    delay: Number,
    stagger: Number
  }

  connect() {
    this.setupDefaultAnimations()
    console.log("Framer Motion controller connected")
  }

  setupDefaultAnimations() {
    // Set default duration if not specified
    this.durationValue = this.durationValue || 0.3
    this.delayValue = this.delayValue || 0
    this.staggerValue = this.staggerValue || 0.1

    // Apply animations based on animation type
    switch (this.animationValue) {
      case 'fadeIn':
        this.fadeInAnimation()
        break
      case 'slideUp':
        this.slideUpAnimation()
        break
      case 'scaleIn':
        this.scaleInAnimation()
        break
      case 'staggerChildren':
        this.staggerChildrenAnimation()
        break
      case 'propertyCard':
        this.propertyCardAnimation()
        break
      case 'searchForm':
        this.searchFormAnimation()
        break
      default:
        this.basicAnimation()
    }
  }

  fadeInAnimation() {
    this.fadeTargets.forEach((element, index) => {
      motion(element, {
        opacity: [0, 1],
        y: [20, 0]
      }, {
        duration: this.durationValue,
        delay: this.delayValue + (index * this.staggerValue)
      })
    })
  }

  slideUpAnimation() {
    this.slideTargets.forEach((element, index) => {
      motion(element, {
        y: [50, 0],
        opacity: [0, 1]
      }, {
        duration: this.durationValue,
        delay: this.delayValue + (index * this.staggerValue),
        ease: "easeOut"
      })
    })
  }

  scaleInAnimation() {
    this.scaleTargets.forEach((element, index) => {
      motion(element, {
        scale: [0.8, 1],
        opacity: [0, 1]
      }, {
        duration: this.durationValue,
        delay: this.delayValue + (index * this.staggerValue),
        ease: "backOut"
      })
    })
  }

  staggerChildrenAnimation() {
    const children = this.element.children
    Array.from(children).forEach((child, index) => {
      motion(child, {
        y: [30, 0],
        opacity: [0, 1]
      }, {
        duration: this.durationValue,
        delay: index * this.staggerValue,
        ease: "easeOut"
      })
    })
  }

  propertyCardAnimation() {
    if (this.hasCardTarget) {
      // Initial state
      motion(this.cardTarget, {
        scale: [0.95, 1],
        opacity: [0, 1],
        y: [20, 0]
      }, {
        duration: 0.5,
        ease: "easeOut"
      })

      // Add hover interactions
      this.setupCardHoverAnimation()
    }
  }

  setupCardHoverAnimation() {
    const card = this.cardTarget

    card.addEventListener('mouseenter', () => {
      motion(card, {
        y: -8,
        scale: 1.02,
        boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)"
      }, {
        duration: 0.3,
        ease: "easeOut"
      })

      // Animate image if present
      const image = card.querySelector('img')
      if (image) {
        motion(image, {
          scale: 1.05
        }, {
          duration: 0.3,
          ease: "easeOut"
        })
      }
    })

    card.addEventListener('mouseleave', () => {
      motion(card, {
        y: 0,
        scale: 1,
        boxShadow: "0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)"
      }, {
        duration: 0.3,
        ease: "easeOut"
      })

      // Reset image scale
      const image = card.querySelector('img')
      if (image) {
        motion(image, {
          scale: 1
        }, {
          duration: 0.3,
          ease: "easeOut"
        })
      }
    })
  }

  searchFormAnimation() {
    // Animate search form elements
    const formElements = this.element.querySelectorAll('input, select, button')

    formElements.forEach((element, index) => {
      motion(element, {
        y: [20, 0],
        opacity: [0, 1]
      }, {
        duration: 0.4,
        delay: index * 0.1,
        ease: "easeOut"
      })
    })
  }

  basicAnimation() {
    // Default animation for elements
    this.animatedElementTargets.forEach((element, index) => {
      motion(element, {
        opacity: [0, 1],
        y: [10, 0]
      }, {
        duration: this.durationValue,
        delay: this.delayValue + (index * this.staggerValue)
      })
    })
  }

  // Action methods for manual triggering
  animate() {
    this.setupDefaultAnimations()
  }

  fadeIn() {
    this.fadeInAnimation()
  }

  slideUp() {
    this.slideUpAnimation()
  }

  scaleIn() {
    this.scaleInAnimation()
  }

  // Modal animations
  showModal() {
    if (this.hasModalTarget) {
      motion(this.modalTarget, {
        opacity: [0, 1],
        scale: [0.9, 1]
      }, {
        duration: 0.3,
        ease: "easeOut"
      })
    }
  }

  hideModal() {
    if (this.hasModalTarget) {
      motion(this.modalTarget, {
        opacity: [1, 0],
        scale: [1, 0.9]
      }, {
        duration: 0.2,
        ease: "easeIn"
      })
    }
  }

  // Button click animation
  buttonClick(event) {
    const button = event.currentTarget

    motion(button, {
      scale: [1, 0.95, 1]
    }, {
      duration: 0.2,
      ease: "easeInOut"
    })
  }

  // Heart animation for favorites
  favoriteHeart(event) {
    const heart = event.currentTarget

    // Scale animation
    motion(heart, {
      scale: [1, 1.3, 1]
    }, {
      duration: 0.3,
      ease: "backOut"
    })

    // Create floating heart effect
    this.createFloatingHeart(heart)
  }

  createFloatingHeart(element) {
    const floatingHeart = document.createElement('div')
    floatingHeart.innerHTML = '❤️'
    floatingHeart.className = 'fixed pointer-events-none text-2xl z-50'

    const rect = element.getBoundingClientRect()
    floatingHeart.style.left = `${rect.left + rect.width / 2}px`
    floatingHeart.style.top = `${rect.top}px`

    document.body.appendChild(floatingHeart)

    motion(floatingHeart, {
      y: -50,
      opacity: [1, 0],
      scale: [1, 1.5]
    }, {
      duration: 1,
      ease: "easeOut"
    }).then(() => {
      document.body.removeChild(floatingHeart)
    })
  }

  // Page transition animation
  pageTransition() {
    motion(this.element, {
      opacity: [0, 1],
      x: [20, 0]
    }, {
      duration: 0.5,
      ease: "easeOut"
    })
  }

  // Infinite animations
  startPulse() {
    const element = this.element

    motion(element, {
      scale: [1, 1.05, 1]
    }, {
      duration: 2,
      repeat: Infinity,
      ease: "easeInOut"
    })
  }

  startFloat() {
    const element = this.element

    motion(element, {
      y: [0, -10, 0]
    }, {
      duration: 3,
      repeat: Infinity,
      ease: "easeInOut"
    })
  }

  // Cleanup
  disconnect() {
    // Cancel any ongoing animations
    console.log("Framer Motion controller disconnected")
  }
}