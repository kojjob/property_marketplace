class Amenity < ApplicationRecord
  has_many :listing_amenities, dependent: :destroy
  has_many :listings, through: :listing_amenities

  # Validations
  validates :name, presence: true, uniqueness: true

  # Scopes
  scope :by_category, ->(category) { where(category: category) }
  scope :popular, -> { joins(:listing_amenities).group(:id).order('COUNT(listing_amenities.id) DESC') }
end