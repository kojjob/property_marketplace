import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    // Show the first tab by default
    this.showTab(0)
  }

  switchTab(event) {
    event.preventDefault()

    const clickedTab = event.currentTarget
    const tabName = clickedTab.dataset.tab

    // Hide all panels
    this.panelTargets.forEach(panel => {
      panel.classList.add('hidden')
    })

    // Remove active state from all tabs
    this.tabTargets.forEach(tab => {
      tab.classList.remove('border-indigo-500', 'text-indigo-600')
      tab.classList.add('border-transparent', 'text-gray-500')
      tab.setAttribute('aria-selected', 'false')
    })

    // Show the selected panel
    const selectedPanel = this.panelTargets.find(panel => panel.dataset.panel === tabName)
    if (selectedPanel) {
      selectedPanel.classList.remove('hidden')
    }

    // Add active state to clicked tab
    clickedTab.classList.remove('border-transparent', 'text-gray-500')
    clickedTab.classList.add('border-indigo-500', 'text-indigo-600')
    clickedTab.setAttribute('aria-selected', 'true')
  }

  showTab(index) {
    // Hide all panels except the one at index
    this.panelTargets.forEach((panel, i) => {
      if (i === index) {
        panel.classList.remove('hidden')
      } else {
        panel.classList.add('hidden')
      }
    })

    // Update tab styles
    this.tabTargets.forEach((tab, i) => {
      if (i === index) {
        tab.classList.remove('border-transparent', 'text-gray-500')
        tab.classList.add('border-indigo-500', 'text-indigo-600')
        tab.setAttribute('aria-selected', 'true')
      } else {
        tab.classList.remove('border-indigo-500', 'text-indigo-600')
        tab.classList.add('border-transparent', 'text-gray-500')
        tab.setAttribute('aria-selected', 'false')
      }
    })
  }
}