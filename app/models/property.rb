class Property < ApplicationRecord
  include PgSearch::Model

  belongs_to :user
  has_many :property_images, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many_attached :images
  has_many_attached :videos
  has_many_attached :vr_content

  # Geocoding functionality
  geocoded_by :full_address
  after_validation :geocode, if: ->(obj) { obj.address_changed? || obj.city_changed? || obj.region_changed? || obj.postal_code_changed? || obj.country_changed? }

  PROPERTY_TYPES = ['House', 'Apartment', 'Condo', 'Townhouse', 'Land', 'Commercial'].freeze
  STATUSES = ['active', 'pending', 'sold', 'rented'].freeze

  # PgSearch configuration for full-text search
  pg_search_scope :search_full_text,
                  against: {
                    title: 'A',
                    description: 'B',
                    address: 'C',
                    city: 'C',
                    region: 'D',
                    country: 'D'
                  },
                  using: {
                    tsearch: {
                      prefix: true,
                      dictionary: 'english'
                    }
                  }

  # Media validations
  validate :acceptable_images
  validate :acceptable_videos
  validate :acceptable_vr_content

  validates :title, presence: true, length: { maximum: 200 }
  validates :description, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :property_type, presence: true, inclusion: { in: PROPERTY_TYPES }
  validates :bedrooms, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :bathrooms, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :square_feet, numericality: { greater_than: 0 }, allow_nil: true
  validates :address, presence: true
  validates :city, presence: true
  validates :region, presence: true
  validates :postal_code, presence: true
  validates :country, presence: true
  validates :status, inclusion: { in: STATUSES }

  # Validations for aliased attributes (for backward compatibility with specs)
  validates :state, presence: true
  validates :zip_code, presence: true

  scope :active, -> { where(status: 'active') }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_price, ->(order = :asc) { order(price: order) }

  before_validation :set_default_status
  before_save :update_formatted_address

  # International address helpers
  def full_address
    parts = [address]
    parts << city if city.present?
    parts << region if region.present?
    parts << postal_code if postal_code.present?
    parts << country if country.present?
    parts.compact.join(', ')
  end

  def location_display
    # Returns a localized location string
    # e.g., "London, UK" or "San Francisco, CA, United States"
    parts = [city]

    # Only show region for countries where it's common (US, Canada, Australia, etc.)
    if ['United States', 'USA', 'Canada', 'Australia'].include?(country)
      parts << region
    end

    # Show country unless it's the default/local country
    # You can customize this based on your app's primary market
    unless country.in?(['United States', 'USA']) # Change this based on your default country
      parts << country
    end

    parts.compact.join(', ')
  end

  def international?
    country.present? && !country.in?(['United States', 'USA'])
  end

  # Aliases for backward compatibility
  alias_attribute :state, :region
  alias_attribute :zip_code, :postal_code

  private

  def set_default_status
    self.status ||= 'active'
    # Set default country if not provided (customize based on your primary market)
    self.country ||= 'United States' if region.present? && country.blank?
  end

  def update_formatted_address
    self.formatted_address = full_address
  end

  def acceptable_images
    return unless images.attached?

    images.each do |image|
      unless image.content_type.in?(%w[image/jpeg image/jpg image/png image/gif])
        errors.add(:images, 'must be a valid image format (JPEG, PNG, GIF)')
      end

      if image.byte_size > 5.megabytes
        errors.add(:images, 'must be less than 5MB')
      end
    end
  end

  def acceptable_videos
    return unless videos.attached?

    videos.each do |video|
      unless video.content_type.in?(%w[video/mp4 video/mpeg video/quicktime video/x-msvideo video/webm])
        errors.add(:videos, 'must be a valid video format (MP4, MPEG, MOV, AVI, WebM)')
      end

      if video.byte_size > 50.megabytes
        errors.add(:videos, 'must be less than 50MB')
      end
    end
  end

  def acceptable_vr_content
    return unless vr_content.attached?

    vr_content.each do |vr_file|
      unless vr_file.content_type.in?(%w[video/mp4 video/webm application/octet-stream model/gltf+json model/gltf-binary])
        errors.add(:vr_content, 'must be a valid VR format (MP4, WebM, glTF, GLB)')
      end

      if vr_file.byte_size > 100.megabytes
        errors.add(:vr_content, 'must be less than 100MB')
      end
    end
  end
end
