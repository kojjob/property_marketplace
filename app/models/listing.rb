class Listing < ApplicationRecord
  belongs_to :property
  belongs_to :user
  has_many :bookings, dependent: :destroy
  has_many :listing_amenities, dependent: :destroy
  has_many :amenities, through: :listing_amenities
  has_many :reviews, as: :reviewable, dependent: :destroy

  # Enums
  enum :listing_type, { rent: 0, sale: 1, short_term: 2, subscription: 3 }
  enum :status, { draft: 0, active: 1, inactive: 2, archived: 3 }
  enum :lease_duration_unit, { days: 0, weeks: 1, months: 2, years: 3 }

  # Validations
  validates :title, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :listing_type, presence: true
  validates :status, presence: true
  validates :lease_duration, presence: true, numericality: { greater_than: 0 }, if: :rental_listing?
  validates :lease_duration_unit, presence: true, if: :rental_listing?

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :available, -> { active.where('available_from IS NULL OR available_from <= ?', Date.current) }
  scope :by_type, ->(type) { where(listing_type: type) }
  scope :price_between, ->(min, max) { where(price: min..max) }

  # Instance methods
  def available?
    active? && (available_from.nil? || available_from <= Date.current)
  end

  def monthly_price
    return nil unless rental_listing?

    case lease_duration_unit
    when 'days'
      (price * 365.0 / 12).round(2)
    when 'weeks'
      (price * 52.0 / 12).round(2)
    when 'months'
      price
    when 'years'
      (price / 12.0).round(2)
    else
      price
    end
  end

  def can_be_booked?(check_in_date, check_out_date)
    return false unless available?

    # Check for overlapping bookings
    overlapping_bookings = bookings
      .where(status: ['pending', 'confirmed'])
      .where('(check_in_date <= ? AND check_out_date >= ?) OR (check_in_date <= ? AND check_out_date >= ?)',
             check_out_date, check_in_date, check_out_date, check_in_date)

    overlapping_bookings.empty?
  end

  private

  def rental_listing?
    listing_type == 'rent'
  end
end