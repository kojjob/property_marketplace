import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search"
export default class extends Controller {
  static targets = ["tabs", "form", "location", "results", "advancedToggle"]
  static values = {
    activeTab: String,
    showAdvanced: Boolean
  }

  connect() {
    this.setupTabSwitching()
    this.setupAnimations()
    console.log("Search controller connected")
  }

  setupTabSwitching() {
    // Initialize active tab
    this.activeTabValue = this.activeTabValue || "all"
    this.updateTabDisplay()
  }

  setupAnimations() {
    // Add smooth transitions to form elements
    if (this.hasFormTarget) {
      this.formTarget.style.transition = "all 0.3s ease"
    }
  }

  // Tab switching
  switchTab(event) {
    event.preventDefault()
    const clickedTab = event.currentTarget
    const tabType = clickedTab.dataset.listingType

    // Update active tab value
    this.activeTabValue = tabType

    // Update visual state
    this.updateTabDisplay()

    // Add a subtle animation
    this.animateTabSwitch(clickedTab)

    // Update hidden form field if exists
    const hiddenField = this.formTarget.querySelector('input[name="listing_type"]')
    if (hiddenField) {
      hiddenField.value = tabType
    }
  }

  updateTabDisplay() {
    if (!this.hasTabsTarget) return

    const tabs = this.tabsTarget.querySelectorAll('.tab')
    tabs.forEach(tab => {
      const tabType = tab.dataset.listingType
      if (tabType === this.activeTabValue) {
        tab.classList.add('tab-active')
        tab.classList.add('bg-primary', 'text-primary-content')
      } else {
        tab.classList.remove('tab-active')
        tab.classList.remove('bg-primary', 'text-primary-content')
      }
    })
  }

  animateTabSwitch(clickedTab) {
    // Add a ripple effect
    clickedTab.style.transform = "scale(0.95)"
    clickedTab.style.transition = "transform 0.1s ease"

    setTimeout(() => {
      clickedTab.style.transform = "scale(1)"
    }, 100)
  }

  // Location autocomplete animation
  focusLocation() {
    if (!this.hasLocationTarget) return

    this.locationTarget.style.transform = "scale(1.02)"
    this.locationTarget.style.boxShadow = "0 0 0 3px rgba(59, 130, 246, 0.1)"
    this.locationTarget.style.transition = "all 0.2s ease"
  }

  blurLocation() {
    if (!this.hasLocationTarget) return

    this.locationTarget.style.transform = "scale(1)"
    this.locationTarget.style.boxShadow = "none"
  }

  // Advanced search toggle
  toggleAdvanced(event) {
    event.preventDefault()
    this.showAdvancedValue = !this.showAdvancedValue

    const advancedSection = this.element.querySelector('.advanced-search')
    if (advancedSection) {
      if (this.showAdvancedValue) {
        this.showAdvancedSection(advancedSection)
      } else {
        this.hideAdvancedSection(advancedSection)
      }
    }

    // Update button text
    if (this.hasAdvancedToggleTarget) {
      this.advancedToggleTarget.textContent = this.showAdvancedValue ?
        'Hide Advanced Search' : 'Advanced Search →'
    }
  }

  showAdvancedSection(section) {
    section.style.display = 'block'
    section.style.maxHeight = '0'
    section.style.opacity = '0'
    section.style.overflow = 'hidden'
    section.style.transition = 'all 0.3s ease'

    // Trigger animation
    requestAnimationFrame(() => {
      section.style.maxHeight = '500px'
      section.style.opacity = '1'
    })
  }

  hideAdvancedSection(section) {
    section.style.maxHeight = '0'
    section.style.opacity = '0'

    setTimeout(() => {
      section.style.display = 'none'
    }, 300)
  }

  // Form submission with loading animation
  submitSearch(event) {
    const submitButton = this.formTarget.querySelector('button[type="submit"]')
    if (submitButton) {
      this.showLoadingState(submitButton)
    }
  }

  showLoadingState(button) {
    const originalText = button.textContent
    button.innerHTML = `
      <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      Searching...
    `
    button.disabled = true

    // Reset after a delay (in case of client-side handling)
    setTimeout(() => {
      button.textContent = originalText
      button.disabled = false
    }, 2000)
  }

  // Real-time search results (for future implementation)
  handleInput(event) {
    const query = event.target.value
    if (query.length > 2) {
      this.debounce(() => {
        this.performLiveSearch(query)
      }, 300)
    }
  }

  performLiveSearch(query) {
    // Future implementation for live search results
    console.log("Performing live search for:", query)
  }

  debounce(func, wait) {
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(func, wait)
  }
}