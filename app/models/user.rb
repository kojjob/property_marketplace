class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :properties, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorited_properties, through: :favorites, source: :property
  has_one :profile, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
