class PropertyImage < ApplicationRecord
  belongs_to :property
  has_one_attached :image

  validates :position, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :image_presence
  validate :image_content_type
  validate :image_file_size

  scope :ordered, -> { order(:position, :created_at) }
  scope :primary, -> { where(position: 0) }

  before_save :set_default_position, if: -> { position.nil? }

  # Image validation methods
  private

  def image_presence
    errors.add(:image, "can't be blank") unless image.attached?
  end

  def image_content_type
    return unless image.attached?

    unless image.content_type.in?(%w[image/jpeg image/jpg image/png image/gif image/webp])
      errors.add(:image, 'must be an image file')
    end
  end

  def image_file_size
    return unless image.attached?

    if image.blob.byte_size > 10.megabytes
      errors.add(:image, 'file size must be less than 10MB')
    end
  end

  def set_default_position
    max_position = property.property_images.maximum(:position) || -1
    self.position = max_position + 1
  end

  public

  # Instance methods
  def primary?
    position == 0
  end

  def image_url
    return nil unless image.attached?
    Rails.application.routes.url_helpers.rails_blob_url(image, only_path: true)
  end

  def image_variants
    return {} unless image.attached?

    {
      thumbnail: Rails.application.routes.url_helpers.rails_representation_url(
        image.variant(resize_to_limit: [150, 150]), only_path: true
      ),
      medium: Rails.application.routes.url_helpers.rails_representation_url(
        image.variant(resize_to_limit: [400, 300]), only_path: true
      ),
      large: Rails.application.routes.url_helpers.rails_representation_url(
        image.variant(resize_to_limit: [800, 600]), only_path: true
      )
    }
  end

  # Class methods
  def self.reorder_images(image_ids)
    return if image_ids.blank?

    transaction do
      image_ids.each_with_index do |image_id, index|
        PropertyImage.where(id: image_id).update_all(position: index)
      end
    end
  end

  def self.bulk_create_from_uploads(property, upload_files)
    return [] if upload_files.blank?

    images = []
    upload_files.each_with_index do |file, index|
      next if file.blank?

      image = property.property_images.build(position: index)
      image.image.attach(file)

      if image.save
        images << image
      end
    end

    images
  end

  def self.normalize_positions(property)
    property.property_images.ordered.each_with_index do |image, index|
      image.update_column(:position, index)
    end
  end
end
