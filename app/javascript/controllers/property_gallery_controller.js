import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="property-gallery"
export default class extends Controller {
  static targets = ["carousel", "counter", "thumbnail"]
  static values = { currentSlide: Number }

  connect() {
    this.currentSlideValue = 1
    this.setupCarousel()
    this.setupThumbnails()
    this.setupKeyboardNavigation()
    console.log("Property gallery controller connected")
  }

  setupCarousel() {
    if (!this.hasCarouselTarget) return

    // Set up intersection observer to track current slide
    this.setupSlideObserver()

    // Auto-update counter
    this.updateCounter()
  }

  setupThumbnails() {
    if (!this.hasThumbnailTarget) return

    this.thumbnailTargets.forEach((thumbnail, index) => {
      thumbnail.addEventListener('click', (event) => {
        event.preventDefault()
        this.goToSlide(index + 1)
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

  setupSlideObserver() {
    if (!window.IntersectionObserver) return

    const slides = this.carouselTarget.querySelectorAll('.carousel-item')

    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const slideId = entry.target.id
          const slideNumber = parseInt(slideId.replace('slide', ''))
          this.currentSlideValue = slideNumber
          this.updateCounter()
          this.updateThumbnailSelection(slideNumber - 1)
        }
      })
    }, {
      threshold: 0.5
    })

    slides.forEach(slide => observer.observe(slide))
  }

  goToSlide(slideNumber) {
    const targetSlide = document.getElementById(`slide${slideNumber}`)
    if (targetSlide) {
      targetSlide.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
      this.currentSlideValue = slideNumber
      this.updateCounter()
    }
  }

  nextSlide() {
    const totalSlides = this.carouselTarget.querySelectorAll('.carousel-item').length
    const nextSlide = this.currentSlideValue >= totalSlides ? 1 : this.currentSlideValue + 1
    this.goToSlide(nextSlide)
  }

  previousSlide() {
    const totalSlides = this.carouselTarget.querySelectorAll('.carousel-item').length
    const prevSlide = this.currentSlideValue <= 1 ? totalSlides : this.currentSlideValue - 1
    this.goToSlide(prevSlide)
  }

  updateCounter() {
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = this.currentSlideValue
    }
  }

  updateThumbnailSelection(activeIndex) {
    if (!this.hasThumbnailTarget) return

    this.thumbnailTargets.forEach((thumbnail, index) => {
      if (index === activeIndex) {
        thumbnail.classList.add('border-primary')
        thumbnail.classList.remove('border-transparent')
      } else {
        thumbnail.classList.remove('border-primary')
        thumbnail.classList.add('border-transparent')
      }
    })
  }

  // Touch/swipe support
  setupTouchNavigation() {
    let startX = null
    let startY = null

    this.carouselTarget.addEventListener('touchstart', (event) => {
      startX = event.touches[0].clientX
      startY = event.touches[0].clientY
    })

    this.carouselTarget.addEventListener('touchend', (event) => {
      if (!startX || !startY) return

      const endX = event.changedTouches[0].clientX
      const endY = event.changedTouches[0].clientY

      const diffX = startX - endX
      const diffY = startY - endY

      // Only trigger if horizontal swipe is more significant than vertical
      if (Math.abs(diffX) > Math.abs(diffY) && Math.abs(diffX) > 50) {
        if (diffX > 0) {
          // Swiped left - go to next slide
          this.nextSlide()
        } else {
          // Swiped right - go to previous slide
          this.previousSlide()
        }
      }

      startX = null
      startY = null
    })
  }

  // Fullscreen gallery (future enhancement)
  openFullscreen() {
    // Implementation for fullscreen gallery modal
    console.log("Opening fullscreen gallery")
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