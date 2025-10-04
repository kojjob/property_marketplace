require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:properties).dependent(:destroy) }
    it { should have_many(:favorites).dependent(:destroy) }
    it { should have_many(:favorited_properties).through(:favorites).source(:property) }
    it { should have_one(:profile).dependent(:destroy) }
    it { should have_many(:verifications).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }

    it 'validates email format' do
      user = build(:user, email: 'invalid_email')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('is invalid')
    end

    it 'accepts valid email formats' do
      valid_emails = [ 'user@example.com', 'USER@foo.COM', 'A_US-ER@foo.bar.org' ]
      valid_emails.each do |valid_email|
        user = build(:user, email: valid_email)
        expect(user).to be_valid
      end
    end
  end

  describe 'Devise modules' do
    it 'includes database_authenticatable' do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it 'includes registerable' do
      expect(User.devise_modules).to include(:registerable)
    end

    it 'includes recoverable' do
      expect(User.devise_modules).to include(:recoverable)
    end

    it 'includes rememberable' do
      expect(User.devise_modules).to include(:rememberable)
    end

    it 'includes validatable' do
      expect(User.devise_modules).to include(:validatable)
    end

    it 'includes confirmable' do
      expect(User.devise_modules).to include(:confirmable)
    end

    it 'includes trackable' do
      expect(User.devise_modules).to include(:trackable)
    end
  end

  describe 'business logic' do
    let(:user) { create(:user) }

    it 'can have multiple properties' do
      property1 = create(:property, user: user)
      property2 = create(:property, user: user)

      expect(user.properties.count).to eq(2)
    end

    it 'can favorite properties' do
      property = create(:property)
      favorite = create(:favorite, user: user, property: property)

      expect(user.favorites.count).to eq(1)
      expect(user.favorited_properties).to include(property)
    end

    it 'destroys associated properties when destroyed' do
      create(:property, user: user)

      expect { user.destroy }.to change { Property.count }.by(-1)
    end

    it 'destroys associated favorites when destroyed' do
      property = create(:property)
      create(:favorite, user: user, property: property)

      expect { user.destroy }.to change { Favorite.count }.by(-1)
    end
  end
end
