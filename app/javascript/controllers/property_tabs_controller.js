import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="property-tabs"
export default class extends Controller {
  static targets = ["tab", "tabContent", "tabsNav"]
  static values = { activeTab: String }

  connect() {
    this.activeTabValue = this.activeTabValue || "overview"
    this.updateTabDisplay()
    console.log("Property tabs controller connected")
  }

  switchTab(event) {
    event.preventDefault()

    const clickedTab = event.currentTarget
    const tabName = clickedTab.dataset.tab

    // Update active tab value
    this.activeTabValue = tabName

    // Update visual state
    this.updateTabDisplay()

    // Add animation to tab switch
    this.animateTabSwitch(clickedTab)
  }

  updateTabDisplay() {
    if (!this.hasTabTarget) return

    // Update tab navigation
    this.tabTargets.forEach(tab => {
      const tabName = tab.dataset.tab
      if (tabName === this.activeTabValue) {
        tab.classList.add('tab-active')
      } else {
        tab.classList.remove('tab-active')
      }
    })

    // Update tab content
    this.tabContentTargets.forEach(content => {
      const tabName = content.dataset.tab
      if (tabName === this.activeTabValue) {
        content.classList.remove('hidden')
        content.classList.add('active')
        // Animate content in
        this.animateContentIn(content)
      } else {
        content.classList.add('hidden')
        content.classList.remove('active')
      }
    })
  }

  animateTabSwitch(clickedTab) {
    // Add ripple effect to clicked tab
    clickedTab.style.transform = "scale(0.98)"
    clickedTab.style.transition = "transform 0.1s ease"

    setTimeout(() => {
      clickedTab.style.transform = "scale(1)"
    }, 100)
  }

  animateContentIn(content) {
    // Fade in animation for content
    content.style.opacity = "0"
    content.style.transform = "translateY(10px)"
    content.style.transition = "all 0.3s ease"

    // Trigger animation
    requestAnimationFrame(() => {
      content.style.opacity = "1"
      content.style.transform = "translateY(0)"
    })
  }

  // Method to programmatically switch tabs
  setActiveTab(tabName) {
    this.activeTabValue = tabName
    this.updateTabDisplay()
  }

  // Get current active tab
  getCurrentTab() {
    return this.activeTabValue
  }
}