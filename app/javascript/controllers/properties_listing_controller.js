import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="properties-listing"
export default class extends Controller {
  static targets = ["searchForm", "filterInput", "sortSelect", "propertiesContainer"]
  static values = {
    currentView: String,
    searchParams: Object
  }

  connect() {
    this.currentViewValue = this.currentViewValue || "grid"
    this.searchParamsValue = this.searchParamsValue || {}

    // Load saved view preference
    this.loadViewPreference()

    // Initialize view display after a brief delay to ensure DOM is ready
    setTimeout(() => {
      this.updateViewDisplay()
    }, 100)

    console.log("Properties listing controller connected with view:", this.currentViewValue)
  }

  // Handle search form submission
  submitSearch(event) {
    event.preventDefault()

    const formData = new FormData(event.target)
    const searchParams = new URLSearchParams()

    // Collect all search parameters
    for (let [key, value] of formData.entries()) {
      if (value.trim() !== '' && value !== 'Any' && value !== 'All Types' && value !== 'Any Price') {
        searchParams.append(key, value)
      }
    }

    // Update URL with search parameters
    const newUrl = `${window.location.pathname}?${searchParams.toString()}`
    window.location.href = newUrl
  }

  // Handle sort change
  handleSort(event) {
    const sortValue = event.target.value
    const currentParams = new URLSearchParams(window.location.search)

    if (sortValue && sortValue !== '') {
      currentParams.set('sort', sortValue)
    } else {
      currentParams.delete('sort')
    }

    window.location.href = `${window.location.pathname}?${currentParams.toString()}`
  }

  // Toggle between grid and list view
  switchToGrid(event) {
    event.preventDefault()
    this.currentViewValue = "grid"
    this.updateViewDisplay()
  }

  switchToList(event) {
    event.preventDefault()
    this.currentViewValue = "list"
    this.updateViewDisplay()
  }

  updateViewDisplay() {
    if (!this.hasPropertiesContainerTarget) {
      console.log("Properties container not found")
      return
    }

    const container = this.propertiesContainerTarget
    const gridToggle = document.querySelector('[data-view="grid"]')
    const listToggle = document.querySelector('[data-view="list"]')

    if (this.currentViewValue === "grid") {
      // Grid view styling
      container.className = "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6"

      // Update toggle buttons
      if (gridToggle) {
        gridToggle.className = "flex items-center justify-center p-2 rounded-md bg-blue-600 text-white shadow-sm"
        const icon = gridToggle.querySelector('svg')
        if (icon) icon.className = "w-4 h-4"
      }
      if (listToggle) {
        listToggle.className = "flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-gray-600 hover:bg-gray-100"
        const icon = listToggle.querySelector('svg')
        if (icon) icon.className = "w-4 h-4"
      }

      // Reset property cards to grid layout
      this.resetCardsToGrid(container)

    } else {
      // List view styling
      container.className = "space-y-4"

      // Update toggle buttons
      if (gridToggle) {
        gridToggle.className = "flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-gray-600 hover:bg-gray-100"
        const icon = gridToggle.querySelector('svg')
        if (icon) icon.className = "w-4 h-4"
      }
      if (listToggle) {
        listToggle.className = "flex items-center justify-center p-2 rounded-md bg-blue-600 text-white shadow-sm"
        const icon = listToggle.querySelector('svg')
        if (icon) icon.className = "w-4 h-4"
      }

      // Update property cards for list view
      this.updateCardsToList(container)
    }

    // Save preference to localStorage
    this.saveViewPreference()
  }

  resetCardsToGrid(container) {
    const propertyCards = container.querySelectorAll('.bg-white.rounded-xl')
    propertyCards.forEach(card => {
      // Skip if already in grid format
      if (!card.classList.contains('flex') || card.classList.contains('flex-col')) {
        return
      }

      // Reset to original grid layout (vertical flex)
      card.className = "bg-white rounded-xl shadow-lg overflow-hidden hover:shadow-xl transition-all duration-300 group flex flex-col"

      // Reset image container
      const imageContainer = card.querySelector('.relative')
      if (imageContainer) {
        imageContainer.className = "relative h-48 overflow-hidden"

        // Reset image sizing for grid view
        const image = imageContainer.querySelector('img')
        if (image) {
          image.className = "w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
        }
      }

      // Find and restore original structure if we have a content wrapper
      const contentWrapper = card.querySelector('.flex-1')
      if (contentWrapper) {
        // Extract the content and actions from the wrapper
        const contentArea = contentWrapper.querySelector('.flex-1.p-6')
        const actionsArea = contentWrapper.querySelector('.px-6.pb-6')

        if (contentArea && actionsArea) {
          // Clone and reset classes
          const newContentArea = contentArea.cloneNode(true)
          const newActionsArea = actionsArea.cloneNode(true)

          newContentArea.className = "p-5"
          newActionsArea.className = "px-5 pb-5"

          // Replace the wrapper with the original structure
          contentWrapper.replaceWith(newContentArea, newActionsArea)
        }
      }
    })
  }

  updateCardsToList(container) {
    const propertyCards = container.querySelectorAll('.bg-white.rounded-xl')
    propertyCards.forEach(card => {
      // Skip if already in list format
      if (card.classList.contains('flex') && !card.classList.contains('flex-col')) {
        return
      }

      // Change to horizontal flex layout
      card.className = "bg-white rounded-xl shadow-lg overflow-hidden hover:shadow-xl transition-all duration-300 group flex"

      // Restructure card layout for list view
      const imageContainer = card.querySelector('.relative')
      const contentArea = card.querySelector('.p-5')
      const actionsArea = card.querySelector('.px-5.pb-5')

      if (imageContainer) {
        imageContainer.className = "relative w-64 h-48 flex-shrink-0 overflow-hidden"

        // Ensure the image inside maintains proper sizing
        const image = imageContainer.querySelector('img')
        if (image) {
          image.className = "w-full h-full object-cover"
        }
      }

      // Create a flex container for content and actions if not already done
      if (contentArea && actionsArea && !contentArea.parentElement.classList.contains('flex-1')) {
        const contentWrapper = document.createElement('div')
        contentWrapper.className = "flex-1 flex flex-col justify-between"

        // Move content and actions into wrapper
        const contentClone = contentArea.cloneNode(true)
        const actionsClone = actionsArea.cloneNode(true)

        contentClone.className = "flex-1 p-6"
        actionsClone.className = "px-6 pb-6"

        contentWrapper.appendChild(contentClone)
        contentWrapper.appendChild(actionsClone)

        // Replace original content
        contentArea.replaceWith(contentWrapper)
        actionsArea.remove()
      }
    })
  }

  // Clear all filters
  clearFilters(event) {
    event.preventDefault()
    window.location.href = window.location.pathname
  }

  // Handle individual filter changes
  updateFilter(event) {
    const filterType = event.target.dataset.filter
    const filterValue = event.target.value

    const currentParams = new URLSearchParams(window.location.search)

    if (filterValue && filterValue !== '' && filterValue !== 'Any' && filterValue !== 'All Types') {
      currentParams.set(filterType, filterValue)
    } else {
      currentParams.delete(filterType)
    }

    // Auto-submit after 500ms delay
    clearTimeout(this.filterTimeout)
    this.filterTimeout = setTimeout(() => {
      window.location.href = `${window.location.pathname}?${currentParams.toString()}`
    }, 500)
  }

  // Handle pagination clicks
  handlePagination(event) {
    const link = event.target.closest('a')
    if (link) {
      // Add loading state
      link.classList.add('opacity-50', 'pointer-events-none')

      // Smooth scroll to top
      window.scrollTo({
        top: 0,
        behavior: 'smooth'
      })
    }
  }

  // Save view preference
  saveViewPreference() {
    localStorage.setItem('propertyViewPreference', this.currentViewValue)
  }

  // Load saved view preference
  loadViewPreference() {
    const saved = localStorage.getItem('propertyViewPreference')
    if (saved && (saved === 'grid' || saved === 'list')) {
      this.currentViewValue = saved
    }
  }

  // Save search preferences
  saveSearchPreferences() {
    const preferences = {
      view: this.currentViewValue,
      searchParams: this.searchParamsValue
    }

    localStorage.setItem('propertySearchPreferences', JSON.stringify(preferences))
  }

  // Load saved search preferences
  loadSearchPreferences() {
    const saved = localStorage.getItem('propertySearchPreferences')
    if (saved) {
      try {
        const preferences = JSON.parse(saved)
        this.currentViewValue = preferences.view || "grid"
        this.searchParamsValue = preferences.searchParams || {}
        this.updateViewDisplay()
      } catch (e) {
        console.log('Error loading search preferences:', e)
      }
    }
  }

  disconnect() {
    this.saveSearchPreferences()
    if (this.filterTimeout) {
      clearTimeout(this.filterTimeout)
    }
  }
}