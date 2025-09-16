class Property < ApplicationRecord
  include PgSearch::Model

  belongs_to :user
  has_many :property_images, dependent: :destroy
  has_many :favorites, dependent: :destroy

  PROPERTY_TYPES = ['House', 'Apartment', 'Condo', 'Townhouse', 'Land', 'Commercial'].freeze
  STATUSES = ['active', 'pending', 'sold', 'rented'].freeze

  # PgSearch configuration for full-text search
  pg_search_scope :search_full_text,
                  against: {
                    title: 'A',
                    description: 'B',
                    address: 'C',
                    city: 'C',
                    state: 'D'
                  },
                  using: {
                    tsearch: {
                      prefix: true,
                      dictionary: 'english'
                    }
                  }

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

  scope :active, -> { where(status: 'active') }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_price, ->(order = :asc) { order(price: order) }

  before_validation :set_default_status

  private

  def set_default_status
    self.status ||= 'active'
  end
end
