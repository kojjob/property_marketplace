import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "indicator"]
  static values = { autoPlay: Boolean, autoPlayInterval: Number }

  connect() {
    this.currentIndex = 0
    this.totalSlides = this.slideTargets.length

    if (this.autoPlayValue) {
      this.startAutoPlay()
    }

    this.showSlide(this.currentIndex)
  }

  disconnect() {
    this.stopAutoPlay()
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
    if (this.totalSlides <= 1) return

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
}