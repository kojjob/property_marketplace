import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropZone", "fileInput", "gallery", "imageTemplate", "reorderInput"]
  static values = {
    maxFiles: { type: Number, default: 10 },
    maxFileSize: { type: Number, default: 10485760 }, // 10MB
    acceptedTypes: { type: Array, default: ["image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp"] }
  }

  connect() {
    this.imageCount = this.galleryTarget.children.length
    this.setupDragAndDrop()
    this.setupFileInput()
    this.initializeSortable()
  }

  setupDragAndDrop() {
    this.dropZoneTarget.addEventListener('dragover', this.handleDragOver.bind(this))
    this.dropZoneTarget.addEventListener('dragenter', this.handleDragEnter.bind(this))
    this.dropZoneTarget.addEventListener('dragleave', this.handleDragLeave.bind(this))
    this.dropZoneTarget.addEventListener('drop', this.handleDrop.bind(this))
  }

  setupFileInput() {
    this.fileInputTarget.addEventListener('change', this.handleFileSelect.bind(this))
  }

  handleDragOver(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropZoneTarget.classList.add('drag-over')
  }

  handleDragEnter(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropZoneTarget.classList.add('drag-over')
  }

  handleDragLeave(event) {
    event.preventDefault()
    event.stopPropagation()

    // Only remove the class if we're actually leaving the drop zone
    if (!this.dropZoneTarget.contains(event.relatedTarget)) {
      this.dropZoneTarget.classList.remove('drag-over')
    }
  }

  handleDrop(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropZoneTarget.classList.remove('drag-over')

    const files = Array.from(event.dataTransfer.files)
    this.processFiles(files)
  }

  handleFileSelect(event) {
    const files = Array.from(event.target.files)
    this.processFiles(files)
  }

  processFiles(files) {
    const validFiles = files.filter(file => this.validateFile(file))

    if (this.imageCount + validFiles.length > this.maxFilesValue) {
      this.showError(`Maximum ${this.maxFilesValue} images allowed. You can only add ${this.maxFilesValue - this.imageCount} more.`)
      return
    }

    validFiles.forEach((file, index) => {
      this.addImageToGallery(file, this.imageCount + index)
    })

    this.imageCount += validFiles.length
    this.updateDropZoneVisibility()
  }

  validateFile(file) {
    // Check file type
    if (!this.acceptedTypesValue.includes(file.type)) {
      this.showError(`${file.name}: Invalid file type. Please upload images only.`)
      return false
    }

    // Check file size
    if (file.size > this.maxFileSizeValue) {
      this.showError(`${file.name}: File too large. Maximum size is ${this.formatFileSize(this.maxFileSizeValue)}.`)
      return false
    }

    return true
  }

  addImageToGallery(file, position) {
    const reader = new FileReader()

    reader.onload = (e) => {
      const imageElement = this.createImageElement(e.target.result, file.name, position)
      this.galleryTarget.appendChild(imageElement)
      this.updateImageOrder()
    }

    reader.readAsDataURL(file)
  }

  createImageElement(src, filename, position) {
    const template = this.imageTemplateTarget.content.cloneNode(true)
    const container = template.querySelector('.image-item')
    const img = template.querySelector('img')
    const caption = template.querySelector('.image-caption')
    const removeBtn = template.querySelector('.remove-image')
    const hiddenInput = template.querySelector('input[type="file"]')

    // Set unique IDs and data attributes
    const uniqueId = `image_${Date.now()}_${position}`
    container.dataset.position = position
    container.dataset.imageId = uniqueId

    // Set image source and alt text
    img.src = src
    img.alt = filename

    // Set caption placeholder
    if (caption) {
      caption.placeholder = `Caption for ${filename}`
      caption.name = `property[property_images_attributes][][caption]`
    }

    // Create a file input for the actual file upload
    if (hiddenInput) {
      hiddenInput.name = `property[property_images_attributes][][image]`
      // Note: We can't set the file directly to a file input for security reasons
      // The file will be handled through form submission
    }

    // Setup remove button
    if (removeBtn) {
      removeBtn.addEventListener('click', (e) => {
        e.preventDefault()
        this.removeImage(container)
      })
    }

    return template
  }

  removeImage(imageElement) {
    imageElement.remove()
    this.imageCount--
    this.updateImageOrder()
    this.updateDropZoneVisibility()
  }

  updateDropZoneVisibility() {
    if (this.imageCount >= this.maxFilesValue) {
      this.dropZoneTarget.style.display = 'none'
    } else {
      this.dropZoneTarget.style.display = 'block'
    }
  }

  initializeSortable() {
    // Initialize drag-and-drop reordering using SortableJS if available
    if (typeof Sortable !== 'undefined') {
      this.sortable = new Sortable(this.galleryTarget, {
        animation: 150,
        ghostClass: 'sortable-ghost',
        chosenClass: 'sortable-chosen',
        dragClass: 'sortable-drag',
        onEnd: () => {
          this.updateImageOrder()
        }
      })
    } else {
      // Fallback: Use native drag and drop API
      this.setupNativeSortable()
    }
  }

  setupNativeSortable() {
    this.galleryTarget.addEventListener('dragstart', this.handleImageDragStart.bind(this))
    this.galleryTarget.addEventListener('dragover', this.handleImageDragOver.bind(this))
    this.galleryTarget.addEventListener('drop', this.handleImageDrop.bind(this))
  }

  handleImageDragStart(event) {
    if (event.target.closest('.image-item')) {
      this.draggedElement = event.target.closest('.image-item')
      event.dataTransfer.effectAllowed = 'move'
      event.dataTransfer.setData('text/html', this.draggedElement.outerHTML)
    }
  }

  handleImageDragOver(event) {
    if (this.draggedElement) {
      event.preventDefault()
      event.dataTransfer.dropEffect = 'move'

      const targetItem = event.target.closest('.image-item')
      if (targetItem && targetItem !== this.draggedElement) {
        const rect = targetItem.getBoundingClientRect()
        const midpoint = rect.left + rect.width / 2

        if (event.clientX < midpoint) {
          targetItem.parentNode.insertBefore(this.draggedElement, targetItem)
        } else {
          targetItem.parentNode.insertBefore(this.draggedElement, targetItem.nextSibling)
        }
      }
    }
  }

  handleImageDrop(event) {
    event.preventDefault()
    this.draggedElement = null
    this.updateImageOrder()
  }

  updateImageOrder() {
    const imageItems = this.galleryTarget.querySelectorAll('.image-item')
    const orderArray = []

    imageItems.forEach((item, index) => {
      item.dataset.position = index

      // Update position input if it exists
      const positionInput = item.querySelector('input[name*="position"]')
      if (positionInput) {
        positionInput.value = index
      }

      // Update order array for existing images
      const imageId = item.dataset.imageId
      if (imageId) {
        orderArray.push(imageId)
      }
    })

    // Update the hidden input with the new order
    if (this.hasReorderInputTarget) {
      this.reorderInputTarget.value = orderArray.join(',')
    }

    // Update primary image indicator
    this.updatePrimaryImageIndicator()
  }

  updatePrimaryImageIndicator() {
    const imageItems = this.galleryTarget.querySelectorAll('.image-item')

    imageItems.forEach((item, index) => {
      const primaryIndicator = item.querySelector('.primary-indicator')
      if (primaryIndicator) {
        if (index === 0) {
          primaryIndicator.textContent = 'Primary'
          primaryIndicator.classList.add('text-green-600', 'font-semibold')
          primaryIndicator.classList.remove('text-gray-400')
        } else {
          primaryIndicator.textContent = `#${index + 1}`
          primaryIndicator.classList.remove('text-green-600', 'font-semibold')
          primaryIndicator.classList.add('text-gray-400')
        }
      }
    })
  }

  // Utility methods
  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  showError(message) {
    // Create a simple error notification
    const errorDiv = document.createElement('div')
    errorDiv.className = 'alert alert-error bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4'
    errorDiv.textContent = message

    // Insert at the top of the drop zone
    this.dropZoneTarget.insertBefore(errorDiv, this.dropZoneTarget.firstChild)

    // Remove after 5 seconds
    setTimeout(() => {
      errorDiv.remove()
    }, 5000)
  }

  // Public methods for external control
  triggerFileSelect() {
    this.fileInputTarget.click()
  }

  clearAllImages() {
    this.galleryTarget.innerHTML = ''
    this.imageCount = 0
    this.updateDropZoneVisibility()
  }

  getImageCount() {
    return this.imageCount
  }
}