import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "minRange", "maxRange", "minPriceLabel", "maxPriceLabel"]

  connect() {
    // Initialize price labels on page load
    this.updatePriceLabels()
    this.setupRangeListeners()
  }

  setupRangeListeners() {
    // Only update labels when range sliders change - NO auto-submit
    if (this.hasMinRangeTarget) {
      this.minRangeTarget.addEventListener('input', () => {
        this.updateMinPriceLabel()
      })
    }

    if (this.hasMaxRangeTarget) {
      this.maxRangeTarget.addEventListener('input', () => {
        this.updateMaxPriceLabel()
      })
    }
  }

  updatePriceLabels() {
    this.updateMinPriceLabel()
    this.updateMaxPriceLabel()
  }

  updateMinPriceLabel() {
    if (!this.hasMinRangeTarget || !this.hasMinPriceLabelTarget) return

    const value = parseInt(this.minRangeTarget.value)
    this.minPriceLabelTarget.textContent = this.formatNumber(value)
  }

  updateMaxPriceLabel() {
    if (!this.hasMaxRangeTarget || !this.hasMaxPriceLabelTarget) return

    const value = parseInt(this.maxRangeTarget.value)
    this.maxPriceLabelTarget.textContent = this.formatNumber(value)
  }

  // Set price range from quick buttons and submit form
  setPrice(event) {
    event.preventDefault()
    const button = event.currentTarget
    const min = button.dataset.min
    const max = button.dataset.max

    if (this.hasMinRangeTarget) {
      this.minRangeTarget.value = min
      this.updateMinPriceLabel()
    }
    if (this.hasMaxRangeTarget) {
      this.maxRangeTarget.value = max
      this.updateMaxPriceLabel()
    }

    // Submit form when quick price button is clicked
    this.formTarget.requestSubmit()
  }

  // Format number with commas
  formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
  }
}