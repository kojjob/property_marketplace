import { Controller } from "@hotwired/stimulus"
import { motion } from "framer-motion"

// Connects to data-controller="property-filter"
export default class extends Controller {
  static targets = [
    "quickFilters", "advancedFilters", "searchInput", "typeFilter", "listingTypeFilter",
    "minPrice", "maxPrice", "minSqft", "maxSqft", "featureCheckbox", "yearBuilt",
    "propertiesGrid", "propertyCard", "resultCount", "emptyState"
  ]

  static values = {
    currentView: { type: String, default: "grid" },
    sortBy: { type: String, default: "newest" },
    selectedBedrooms: Number,
    selectedBathrooms: Number
  }

  connect() {
    this.originalCards = Array.from(this.propertyCardTargets)
    this.updateResultCount()
    console.log("Property filter controller connected")
  }

  toggleAdvancedFilters() {
    const filters = this.advancedFiltersTarget
    const isHidden = filters.classList.contains('hidden')

    if (isHidden) {
      filters.classList.remove('hidden')
      // Animate in
      motion(filters,
        { opacity: [0, 1], y: [-20, 0] },
        { duration: 0.3, ease: "easeOut" }
      )
    } else {
      // Animate out
      motion(filters,
        { opacity: [1, 0], y: [0, -20] },
        { duration: 0.3, ease: "easeIn" }
      ).then(() => {
        filters.classList.add('hidden')
      })
    }
  }

  setGridView(event) {
    event.preventDefault()
    this.currentViewValue = "grid"
    this.updateViewButtons()
    this.updateGridLayout()
  }

  setListView(event) {
    event.preventDefault()
    this.currentViewValue = "list"
    this.updateViewButtons()
    this.updateGridLayout()
  }

  updateViewButtons() {
    const buttons = this.element.querySelectorAll('.btn-group .btn')
    buttons.forEach((btn, index) => {
      if ((this.currentViewValue === "grid" && index === 0) ||
          (this.currentViewValue === "list" && index === 1)) {
        btn.classList.add('btn-active')
      } else {
        btn.classList.remove('btn-active')
      }
    })
  }

  updateGridLayout() {
    const grid = this.propertiesGridTarget

    if (this.currentViewValue === "list") {
      grid.className = "space-y-4"
      this.propertyCardTargets.forEach(card => {
        card.className = "card card-side bg-base-100 shadow-xl property-card-hover fade-in"
      })
    } else {
      grid.className = "grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6"
      this.propertyCardTargets.forEach(card => {
        card.className = "card bg-base-100 shadow-xl property-card-hover fade-in"
      })
    }
  }

  sortBy(event) {
    event.preventDefault()
    const sortType = event.currentTarget.dataset.sort
    this.sortByValue = sortType
    this.applySorting()
  }

  applySorting() {
    const cards = Array.from(this.propertyCardTargets)

    cards.sort((a, b) => {
      switch (this.sortByValue) {
        case 'price_low':
          return parseInt(a.dataset.price) - parseInt(b.dataset.price)
        case 'price_high':
          return parseInt(b.dataset.price) - parseInt(a.dataset.price)
        case 'size':
          return parseInt(b.dataset.sqft || 0) - parseInt(a.dataset.sqft || 0)
        case 'newest':
        default:
          return 0 // Keep original order for newest
      }
    })

    // Animate the reordering
    this.animateCardReorder(cards)
  }

  animateCardReorder(sortedCards) {
    const grid = this.propertiesGridTarget

    // Animate out
    motion(this.propertyCardTargets,
      { opacity: 0, scale: 0.9 },
      { duration: 0.2, ease: "easeIn" }
    ).then(() => {
      // Reorder DOM
      sortedCards.forEach(card => grid.appendChild(card))

      // Animate in
      motion(this.propertyCardTargets,
        { opacity: 1, scale: 1 },
        { duration: 0.3, delay: 0.1, ease: "easeOut" }
      )
    })
  }

  selectBedrooms(event) {
    event.preventDefault()
    const bedrooms = parseInt(event.currentTarget.dataset.bedrooms)

    // Toggle selection
    if (this.selectedBedroomsValue === bedrooms) {
      this.selectedBedroomsValue = null
      event.currentTarget.classList.remove('btn-primary')
      event.currentTarget.classList.add('btn-outline')
    } else {
      // Deselect others
      this.element.querySelectorAll('[data-bedrooms]').forEach(btn => {
        btn.classList.remove('btn-primary')
        btn.classList.add('btn-outline')
      })

      // Select current
      this.selectedBedroomsValue = bedrooms
      event.currentTarget.classList.remove('btn-outline')
      event.currentTarget.classList.add('btn-primary')
    }

    this.filterProperties()
  }

  selectBathrooms(event) {
    event.preventDefault()
    const bathrooms = parseInt(event.currentTarget.dataset.bathrooms)

    // Toggle selection
    if (this.selectedBathroomsValue === bathrooms) {
      this.selectedBathroomsValue = null
      event.currentTarget.classList.remove('btn-primary')
      event.currentTarget.classList.add('btn-outline')
    } else {
      // Deselect others
      this.element.querySelectorAll('[data-bathrooms]').forEach(btn => {
        btn.classList.remove('btn-primary')
        btn.classList.add('btn-outline')
      })

      // Select current
      this.selectedBathroomsValue = bathrooms
      event.currentTarget.classList.remove('btn-outline')
      event.currentTarget.classList.add('btn-primary')
    }

    this.filterProperties()
  }

  filterProperties() {
    const searchTerm = this.hasSearchInputTarget ? this.searchInputTarget.value.toLowerCase() : ""
    const propertyType = this.hasTypeFilterTarget ? this.typeFilterTarget.value : ""
    const listingType = this.hasListingTypeFilterTarget ? this.listingTypeFilterTarget.value : ""
    const minPrice = this.hasMinPriceTarget ? parseInt(this.minPriceTarget.value) || 0 : 0
    const maxPrice = this.hasMaxPriceTarget ? parseInt(this.maxPriceTarget.value) || Infinity : Infinity
    const minSqft = this.hasMinSqftTarget ? parseInt(this.minSqftTarget.value) || 0 : 0
    const maxSqft = this.hasMaxSqftTarget ? parseInt(this.maxSqftTarget.value) || Infinity : Infinity

    // Get selected features
    const selectedFeatures = this.featureCheckboxTargets
      .filter(checkbox => checkbox.checked)
      .map(checkbox => checkbox.dataset.feature)

    let visibleCount = 0

    this.propertyCardTargets.forEach(card => {
      const cardPrice = parseInt(card.dataset.price)
      const cardSqft = parseInt(card.dataset.sqft || 0)
      const cardBedrooms = parseInt(card.dataset.bedrooms || 0)
      const cardBathrooms = parseInt(card.dataset.bathrooms || 0)
      const cardCity = card.dataset.city?.toLowerCase() || ""
      const cardState = card.dataset.state?.toLowerCase() || ""
      const cardPropertyType = card.dataset.propertyType?.toLowerCase() || ""
      const cardListingType = card.dataset.listingType?.toLowerCase() || ""

      let shouldShow = true

      // Search filter
      if (searchTerm && !cardCity.includes(searchTerm) &&
          !cardState.includes(searchTerm) &&
          !cardPropertyType.includes(searchTerm)) {
        shouldShow = false
      }

      // Property type filter
      if (propertyType && cardPropertyType !== propertyType.toLowerCase()) {
        shouldShow = false
      }

      // Listing type filter
      if (listingType && cardListingType !== listingType.toLowerCase()) {
        shouldShow = false
      }

      // Price filter
      if (cardPrice < minPrice || cardPrice > maxPrice) {
        shouldShow = false
      }

      // Square footage filter
      if (cardSqft < minSqft || cardSqft > maxSqft) {
        shouldShow = false
      }

      // Bedrooms filter
      if (this.selectedBedroomsValue && cardBedrooms < this.selectedBedroomsValue) {
        shouldShow = false
      }

      // Bathrooms filter
      if (this.selectedBathroomsValue && cardBathrooms < this.selectedBathroomsValue) {
        shouldShow = false
      }

      // Show/hide card with animation
      if (shouldShow) {
        if (card.style.display === 'none') {
          card.style.display = 'block'
          motion(card,
            { opacity: [0, 1], scale: [0.9, 1] },
            { duration: 0.3, ease: "easeOut" }
          )
        }
        visibleCount++
      } else {
        if (card.style.display !== 'none') {
          motion(card,
            { opacity: [1, 0], scale: [1, 0.9] },
            { duration: 0.2, ease: "easeIn" }
          ).then(() => {
            card.style.display = 'none'
          })
        }
      }
    })

    this.updateResultCount(visibleCount)
    this.toggleEmptyState(visibleCount === 0)
  }

  updateResultCount(count = null) {
    if (this.hasResultCountTarget) {
      const displayCount = count !== null ? count : this.propertyCardTargets.length
      this.resultCountTarget.textContent = displayCount
    }
  }

  toggleEmptyState(show) {
    if (this.hasEmptyStateTarget) {
      if (show) {
        this.emptyStateTarget.classList.remove('hidden')
        motion(this.emptyStateTarget,
          { opacity: [0, 1], y: [20, 0] },
          { duration: 0.3, ease: "easeOut" }
        )
      } else {
        this.emptyStateTarget.classList.add('hidden')
      }
    }
  }

  clearFilters() {
    // Clear all form inputs
    if (this.hasSearchInputTarget) this.searchInputTarget.value = ""
    if (this.hasTypeFilterTarget) this.typeFilterTarget.value = ""
    if (this.hasListingTypeFilterTarget) this.listingTypeFilterTarget.value = ""
    if (this.hasMinPriceTarget) this.minPriceTarget.value = ""
    if (this.hasMaxPriceTarget) this.maxPriceTarget.value = ""
    if (this.hasMinSqftTarget) this.minSqftTarget.value = ""
    if (this.hasMaxSqftTarget) this.maxSqftTarget.value = ""

    // Clear feature checkboxes
    this.featureCheckboxTargets.forEach(checkbox => {
      checkbox.checked = false
    })

    // Clear year built
    if (this.hasYearBuiltTarget) this.yearBuiltTarget.value = ""

    // Clear bedroom/bathroom selections
    this.selectedBedroomsValue = null
    this.selectedBathroomsValue = null

    this.element.querySelectorAll('[data-bedrooms], [data-bathrooms]').forEach(btn => {
      btn.classList.remove('btn-primary')
      btn.classList.add('btn-outline')
    })

    // Show all cards
    this.propertyCardTargets.forEach(card => {
      card.style.display = 'block'
      motion(card,
        { opacity: [0, 1], scale: [0.9, 1] },
        { duration: 0.3, ease: "easeOut" }
      )
    })

    this.updateResultCount()
    this.toggleEmptyState(false)
  }

  applyFilters() {
    this.filterProperties()

    // Add visual feedback
    const applyButton = this.element.querySelector('[data-action*="applyFilters"]')
    if (applyButton) {
      motion(applyButton,
        { scale: [1, 0.95, 1] },
        { duration: 0.2, ease: "easeInOut" }
      )
    }
  }

  disconnect() {
    console.log("Property filter controller disconnected")
  }
}