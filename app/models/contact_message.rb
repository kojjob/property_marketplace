class ContactMessage < ApplicationRecord
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, allow_blank: true, format: { with: /\A[\d\s\-\+\(\)]+\z/, message: "must be a valid phone number" }
  validates :subject, presence: true, length: { minimum: 3, maximum: 200 }
  validates :message, presence: true, length: { minimum: 10, maximum: 5000 }
end
