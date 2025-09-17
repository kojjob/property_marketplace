class Session < ApplicationRecord
  belongs_to :user

  validates :session_token, presence: true, uniqueness: true

  scope :active, -> { where("expires_at > ?", Time.current) }

  def expired?
    expires_at < Time.current
  end

  def self.find_by_token(token)
    active.find_by(session_token: token)
  end
end
