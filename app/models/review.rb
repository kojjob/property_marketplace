class Review < ApplicationRecord
  # Associations
  belongs_to :reviewable, polymorphic: true
  belongs_to :reviewer, class_name: 'User', foreign_key: 'reviewer_id'
  belongs_to :booking, optional: true
  belongs_to :responder, class_name: 'User', foreign_key: 'response_by_id', optional: true

  # Validations
  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :review_type, presence: true
  validates :title, length: { maximum: 100 }, allow_blank: true
  validates :content, length: { minimum: 10, maximum: 1000 }, allow_blank: true

  # Custom validation for whitespace-only content - this runs after length validation
  validate :content_not_just_whitespace

  # Custom validations
  validate :reviewer_cannot_review_own_property
  validate :one_review_per_booking
  validate :booking_must_be_completed

  # Enums
  enum :review_type, {
    tenant_to_property: 0,
    landlord_to_tenant: 1,
    tenant_to_landlord: 2,
    property_general: 3
  }

  enum :status, {
    pending: 0,
    published: 1,
    flagged: 2,
    removed: 3
  }

  # Scopes
  scope :published, -> { where(status: 'published') }
  scope :pending, -> { where(status: 'pending') }
  scope :high_rating, -> { where('rating >= ?', 4) }
  scope :low_rating, -> { where('rating <= ?', 2) }
  scope :recent, -> { where('reviews.created_at > ?', 30.days.ago) }
  scope :for_listing, ->(listing_id) { where(reviewable_type: 'Listing', reviewable_id: listing_id) }

  # Class methods
  def self.average_rating_for(reviewable)
    published.where(reviewable: reviewable).average(:rating) || 0
  end

  # Instance methods
  def helpful_votes_count
    helpful_count || 0
  end

  def response_from_owner
    response
  end

  def can_be_edited?
    return false if response.present?
    return false if created_at < 48.hours.ago
    true
  end

  private

  def content_not_just_whitespace
    # Check if content is only whitespace (including spaces, tabs, newlines)
    if content.present? && content.match?(/\A\s+\z/)
      errors.add(:content, "can't be just whitespace")
    end
  end

  def reviewer_cannot_review_own_property
    return unless reviewable_type == 'Listing' && reviewable && reviewer

    begin
      if reviewable.user_id == reviewer_id
        errors.add(:reviewer, "can't review own property")
      end
    rescue NoMethodError
      # Handle case where reviewable doesn't respond to user_id
      return
    end
  end

  def one_review_per_booking
    return unless booking_id.present?

    existing_review = Review.where(
      booking_id: booking_id,
      review_type: review_type
    ).where.not(id: id)

    if existing_review.exists?
      errors.add(:booking, "already has a review of this type")
    end
  end

  def booking_must_be_completed
    return unless booking.present?

    unless booking.completed?
      errors.add(:booking, "must be completed before reviewing")
    end
  end
end