import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="property-gallery"
export default class extends Controller {
  static targets = ["slide", "counter", "thumbnail", "prevBtn", "nextBtn"]
  static values = { currentSlide: Number }

  connect() {
    this.currentSlideValue = 0
    this.totalSlides = this.slideTargets.length
    this.setupCarousel()
    this.setupThumbnails()
    this.setupKeyboardNavigation()
    this.setupTouchNavigation()
    console.log("Property gallery controller connected", this.totalSlides, "slides")
  }

  setupCarousel() {
    if (this.totalSlides === 0) return

    // Initialize first slide
    this.showSlide(0)
    this.updateCounter()
  }

  setupThumbnails() {
    if (!this.hasThumbnailTarget) return

    this.thumbnailTargets.forEach((thumbnail, index) => {
      thumbnail.addEventListener('click', (event) => {
        event.preventDefault()
        this.showSlide(index)
        this.updateThumbnailSelection(index)
      })
    })

    // Set initial thumbnail selection
    this.updateThumbnailSelection(0)
  }

  setupKeyboardNavigation() {
    document.addEventListener('keydown', (event) => {
      if (event.key === 'ArrowLeft') {
        this.previousSlide()
      } else if (event.key === 'ArrowRight') {
        this.nextSlide()
      }
    })
  }

  showSlide(index) {
    if (index < 0 || index >= this.totalSlides) return

    // Hide all slides
    this.slideTargets.forEach((slide, i) => {
      if (i === index) {
        slide.classList.remove('opacity-0')
        slide.classList.add('opacity-100')
      } else {
        slide.classList.remove('opacity-100')
        slide.classList.add('opacity-0')
      }
    })

    this.currentSlideValue = index
    this.updateCounter()
    this.updateThumbnailSelection(index)
  }

  showImage(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.showSlide(index)
  }

  nextImage() {
    const nextIndex = this.currentSlideValue >= this.totalSlides - 1 ? 0 : this.currentSlideValue + 1
    this.showSlide(nextIndex)
  }

  previousImage() {
    const prevIndex = this.currentSlideValue <= 0 ? this.totalSlides - 1 : this.currentSlideValue - 1
    this.showSlide(prevIndex)
  }

  nextSlide() {
    this.nextImage()
  }

  previousSlide() {
    this.previousImage()
  }

  updateCounter() {
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = this.currentSlideValue + 1
    }
  }

  updateThumbnailSelection(activeIndex) {
    if (!this.hasThumbnailTarget) return

    this.thumbnailTargets.forEach((thumbnail, index) => {
      if (index === activeIndex) {
        thumbnail.classList.remove('border-gray-200')
        thumbnail.classList.add('border-blue-500', 'ring-2', 'ring-blue-200')
      } else {
        thumbnail.classList.remove('border-blue-500', 'ring-2', 'ring-blue-200')
        thumbnail.classList.add('border-gray-200')
      }
    })
  }

  // Touch/swipe support
  setupTouchNavigation() {
    let startX = null
    let startY = null

    this.element.addEventListener('touchstart', (event) => {
      startX = event.touches[0].clientX
      startY = event.touches[0].clientY
    })

    this.element.addEventListener('touchend', (event) => {
      if (!startX || !startY) return

      const endX = event.changedTouches[0].clientX
      const endY = event.changedTouches[0].clientY

      const diffX = startX - endX
      const diffY = startY - endY

      // Only trigger if horizontal swipe is more significant than vertical
      if (Math.abs(diffX) > Math.abs(diffY) && Math.abs(diffX) > 50) {
        if (diffX > 0) {
          // Swiped left - go to next slide
          this.nextImage()
        } else {
          // Swiped right - go to previous slide
          this.previousImage()
        }
      }

      startX = null
      startY = null
    })
  }

  // Fullscreen toggle
  toggleFullscreen() {
    console.log("Toggling fullscreen gallery")
    // For now, just open a modal with the current image
    this.openImageModal()
  }

  openImageModal() {
    // Create a simple modal overlay for fullscreen view
    const modal = document.createElement('div')
    modal.className = 'fixed inset-0 bg-black bg-opacity-90 z-50 flex items-center justify-center p-4'
    modal.addEventListener('click', () => modal.remove())

    const currentSlide = this.slideTargets[this.currentSlideValue]
    const img = currentSlide.querySelector('img')

    if (img) {
      const modalImg = img.cloneNode()
      modalImg.className = 'max-w-full max-h-full object-contain'
      modal.appendChild(modalImg)
    }

    document.body.appendChild(modal)
  }

  // Auto-play functionality (future enhancement)
  startAutoPlay() {
    this.autoPlayInterval = setInterval(() => {
      this.nextSlide()
    }, 5000) // 5 seconds
  }

  stopAutoPlay() {
    if (this.autoPlayInterval) {
      clearInterval(this.autoPlayInterval)
      this.autoPlayInterval = null
    }
  }

  disconnect() {
    this.stopAutoPlay()
    console.log("Property gallery controller disconnected")
  }
}