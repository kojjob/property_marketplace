class User < ApplicationRecord
  include Pay::Billable

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable

  # Associations
  has_many :payments, dependent: :destroy
  has_many :properties, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorited_properties, through: :favorites, source: :property
  has_one :profile, dependent: :destroy
  has_many :written_reviews, class_name: "Review", foreign_key: "reviewer_id", dependent: :destroy
  has_many :received_reviews, as: :reviewable, class_name: "Review", dependent: :destroy
  has_many :verifications, dependent: :destroy

  # Callbacks
  after_create :create_profile

  # Verification helper methods
  def identity_verified?
    verifications.where(verification_type: "identity", status: "approved").exists?
  end

  def email_verified?
    verifications.where(verification_type: "email", status: "approved").exists?
  end

  def phone_verified?
    verifications.where(verification_type: "phone", status: "approved").exists?
  end

  def address_verified?
    verifications.where(verification_type: "address", status: "approved").exists?
  end

  def background_check_verified?
    verifications.where(verification_type: "background_check", status: "approved").exists?
  end

  def income_verified?
    verifications.where(verification_type: "income", status: "approved").exists?
  end

  def fully_verified?
    identity_verified? && email_verified? && phone_verified?
  end

  # Get or create profile
  def profile_or_build
    profile || build_profile
  end

  private

  def create_profile
    build_profile(first_name: email.split("@").first.capitalize) unless profile.present?
  end
end
