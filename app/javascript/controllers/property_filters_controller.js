import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "minRange", "maxRange", "minPriceLabel", "maxPriceLabel", "priceRangeTitle", "minPriceText", "maxPriceText", "quickButtons"]

  connect() {
    this.setupListingTypeListeners()
    this.setupRangeListeners()
    this.updatePriceRanges()
  }

  setupListingTypeListeners() {
    // Listen for changes to listing type radio buttons
    const listingTypeRadios = this.element.querySelectorAll('input[name="listing_type"]')
    listingTypeRadios.forEach(radio => {
      radio.addEventListener('change', () => {
        this.updatePriceRanges()
      })
    })
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

  updatePriceRanges() {
    const selectedListingType = this.getSelectedListingType()

    if (selectedListingType === 'rent') {
      this.setRentRanges()
    } else {
      this.setSaleRanges()
    }

    this.updatePriceLabels()
    this.updateQuickButtons(selectedListingType)
  }

  getSelectedListingType() {
    const checkedRadio = this.element.querySelector('input[name="listing_type"]:checked')
    return checkedRadio ? checkedRadio.value : 'sale'
  }

  setRentRanges() {
    // Set title and labels for rent
    this.priceRangeTitleTarget.textContent = 'Monthly Rent Range'
    this.minPriceTextTarget.innerHTML = 'Min Rent: $<span data-property-filters-target="minPriceLabel">0</span>/month'
    this.maxPriceTextTarget.innerHTML = 'Max Rent: $<span data-property-filters-target="maxPriceLabel">10,000</span>/month'

    // Update range attributes for rent (0-10K, step 100)
    this.minRangeTarget.setAttribute('min', '0')
    this.minRangeTarget.setAttribute('max', '10000')
    this.minRangeTarget.setAttribute('step', '100')
    this.minRangeTarget.value = Math.min(this.minRangeTarget.value || 0, 10000)

    this.maxRangeTarget.setAttribute('min', '0')
    this.maxRangeTarget.setAttribute('max', '10000')
    this.maxRangeTarget.setAttribute('step', '100')
    this.maxRangeTarget.value = Math.min(this.maxRangeTarget.value || 10000, 10000)
  }

  setSaleRanges() {
    // Set title and labels for sale
    this.priceRangeTitleTarget.textContent = 'Price Range'
    this.minPriceTextTarget.innerHTML = 'Min Price: $<span data-property-filters-target="minPriceLabel">0</span>'
    this.maxPriceTextTarget.innerHTML = 'Max Price: $<span data-property-filters-target="maxPriceLabel">2,000,000</span>'

    // Update range attributes for sale (0-2M, step 10K)
    this.minRangeTarget.setAttribute('min', '0')
    this.minRangeTarget.setAttribute('max', '2000000')
    this.minRangeTarget.setAttribute('step', '10000')
    this.minRangeTarget.value = Math.min(this.minRangeTarget.value || 0, 2000000)

    this.maxRangeTarget.setAttribute('min', '0')
    this.maxRangeTarget.setAttribute('max', '2000000')
    this.maxRangeTarget.setAttribute('step', '10000')
    this.maxRangeTarget.value = Math.min(this.maxRangeTarget.value || 2000000, 2000000)
  }

  updateQuickButtons(listingType) {
    if (listingType === 'rent') {
      this.quickButtonsTarget.innerHTML = this.getRentQuickButtons()
    } else {
      this.quickButtonsTarget.innerHTML = this.getSaleQuickButtons()
    }
  }

  getRentQuickButtons() {
    return `
      <button type="button" class="px-3 py-1 bg-gray-50 rounded-lg hover:bg-gray-100" data-action="click->property-filters#setPrice" data-min="0" data-max="1000">Under $1K</button>
      <button type="button" class="px-3 py-1 bg-gray-50 rounded-lg hover:bg-gray-100" data-action="click->property-filters#setPrice" data-min="1000" data-max="2000">$1K - $2K</button>
      <button type="button" class="px-3 py-1 bg-gray-50 rounded-lg hover:bg-gray-100" data-action="click->property-filters#setPrice" data-min="2000" data-max="3000">$2K - $3K</button>
      <button type="button" class="px-3 py-1 bg-gray-50 rounded-lg hover:bg-gray-100" data-action="click->property-filters#setPrice" data-min="3000" data-max="10000">$3K+</button>
    `
  }

  getSaleQuickButtons() {
    return `
      <button type="button" class="px-3 py-1 bg-gray-50 rounded-lg hover:bg-gray-100" data-action="click->property-filters#setPrice" data-min="0" data-max="250000">Under $250K</button>
      <button type="button" class="px-3 py-1 bg-gray-50 rounded-lg hover:bg-gray-100" data-action="click->property-filters#setPrice" data-min="250000" data-max="500000">$250K - $500K</button>
      <button type="button" class="px-3 py-1 bg-gray-50 rounded-lg hover:bg-gray-100" data-action="click->property-filters#setPrice" data-min="500000" data-max="1000000">$500K - $1M</button>
      <button type="button" class="px-3 py-1 bg-gray-50 rounded-lg hover:bg-gray-100" data-action="click->property-filters#setPrice" data-min="1000000" data-max="2000000">$1M+</button>
    `
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