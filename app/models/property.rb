class Property < ApplicationRecord
  include Searchable

  belongs_to :user
  has_many :property_images, dependent: :destroy
  has_many :favorites, dependent: :destroy

  # Support for nested attributes (for image management)
  accepts_nested_attributes_for :property_images, allow_destroy: true, reject_if: :all_blank

  PROPERTY_TYPES = ['House', 'Apartment', 'Condo', 'Townhouse', 'Land', 'Commercial'].freeze
  STATUSES = ['active', 'pending', 'sold', 'rented'].freeze

  validates :title, presence: true, length: { maximum: 200 }
  validates :description, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :property_type, presence: true, inclusion: { in: PROPERTY_TYPES }
  validates :bedrooms, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :bathrooms, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :square_feet, numericality: { greater_than: 0 }, allow_nil: true
  validates :address, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :zip_code, presence: true
  validates :status, inclusion: { in: STATUSES }

  # Additional scopes for common queries
  scope :featured, -> { active.limit(6) }
  scope :with_images, -> { includes(:property_images) }

  before_validation :set_default_status

  # Helper methods
  def primary_image
    property_images.order(:position).first
  end

  def has_images?
    property_images.any?
  end

  private

  def set_default_status
    self.status ||= 'active'
  end
end
