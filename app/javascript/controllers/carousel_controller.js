import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "indicator"]
  static values = { autoPlay: Boolean, autoPlayInterval: Number }

  connect() {
    this.currentIndex = 0
    this.totalSlides = this.slideTargets.length
    this.isVisible = false

    // Use intersection observer for performance
    this.setupIntersectionObserver()

    // Debounce navigation to prevent rapid clicking
    this.debouncedNext = this.debounce(this.next.bind(this), 300)
    this.debouncedPrev = this.debounce(this.prev.bind(this), 300)

    // Add keyboard navigation
    this.keydownHandler = this.handleKeydown.bind(this)
    this.element.addEventListener('keydown', this.keydownHandler)

    this.showSlide(this.currentIndex)
  }

  disconnect() {
    this.stopAutoPlay()
    if (this.observer) {
      this.observer.disconnect()
    }
    if (this.keydownHandler) {
      this.element.removeEventListener('keydown', this.keydownHandler)
    }
  }

  next() {
    this.currentIndex = (this.currentIndex + 1) % this.totalSlides
    this.showSlide(this.currentIndex)
    this.resetAutoPlay()
  }

  prev() {
    this.currentIndex = (this.currentIndex - 1 + this.totalSlides) % this.totalSlides
    this.showSlide(this.currentIndex)
    this.resetAutoPlay()
  }

  // Performance-optimized methods
  setupIntersectionObserver() {
    if ('IntersectionObserver' in window) {
      this.observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          this.isVisible = entry.isIntersecting
          if (this.isVisible && this.autoPlayValue) {
            this.startAutoPlay()
          } else {
            this.stopAutoPlay()
          }
        })
      }, { threshold: 0.1 })

      this.observer.observe(this.element)
    } else if (this.autoPlayValue) {
      // Fallback for older browsers
      this.startAutoPlay()
    }
  }

  debounce(func, delay) {
    let timeoutId
    return (...args) => {
      clearTimeout(timeoutId)
      timeoutId = setTimeout(() => func.apply(this, args), delay)
    }
  }

  goTo(event) {
    const index = parseInt(event.currentTarget.dataset.carouselIndex)
    this.currentIndex = index
    this.showSlide(this.currentIndex)
    this.resetAutoPlay()
  }

  showSlide(index) {
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

    // Update indicators
    this.indicatorTargets.forEach((indicator, i) => {
      if (i === index) {
        indicator.classList.remove('bg-opacity-50')
        indicator.classList.add('bg-opacity-100')
      } else {
        indicator.classList.remove('bg-opacity-100')
        indicator.classList.add('bg-opacity-50')
      }
    })
  }

  startAutoPlay() {
    if (this.totalSlides <= 1 || (!this.isVisible && 'IntersectionObserver' in window)) return

    this.autoPlayTimer = setInterval(() => {
      this.next()
    }, this.autoPlayIntervalValue || 5000)
  }

  stopAutoPlay() {
    if (this.autoPlayTimer) {
      clearInterval(this.autoPlayTimer)
      this.autoPlayTimer = null
    }
  }

  resetAutoPlay() {
    if (this.autoPlayValue) {
      this.stopAutoPlay()
      this.startAutoPlay()
    }
  }

  // Keyboard navigation support
  handleKeydown(event) {
    if (this.totalSlides <= 1) return

    switch (event.key) {
      case 'ArrowLeft':
        event.preventDefault()
        this.prev()
        break
      case 'ArrowRight':
        event.preventDefault()
        this.next()
        break
      case 'Home':
        event.preventDefault()
        this.currentIndex = 0
        this.showSlide(this.currentIndex)
        this.resetAutoPlay()
        break
      case 'End':
        event.preventDefault()
        this.currentIndex = this.totalSlides - 1
        this.showSlide(this.currentIndex)
        this.resetAutoPlay()
        break
    }
  }
}