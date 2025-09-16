class PropertyImage < ApplicationRecord
  belongs_to :property

  validates :image_url, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :ordered, -> { order(:position, :created_at) }
end
