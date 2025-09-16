require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:sessions).dependent(:destroy) }
    it { should have_many(:properties).dependent(:destroy) }
    it { should have_many(:favorites).dependent(:destroy) }
    it { should have_many(:favorited_properties).through(:favorites).source(:property) }
  end

  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email_address) }
    it { should validate_uniqueness_of(:email_address).ignoring_case_sensitivity }
    it { should have_secure_password }

    it 'validates email format' do
      user = build(:user, email_address: 'invalid_email')
      expect(user).not_to be_valid
      expect(user.errors[:email_address]).to include('is invalid')
    end

    it 'accepts valid email formats' do
      valid_emails = ['user@example.com', 'USER@foo.COM', 'A_US-ER@foo.bar.org']
      valid_emails.each do |valid_email|
        user = build(:user, email_address: valid_email)
        expect(user).to be_valid
      end
    end
  end

  describe 'normalizations' do
    it 'normalizes email address by downcasing and stripping whitespace' do
      user = create(:user, email_address: '  TEST@EXAMPLE.COM  ')
      expect(user.email_address).to eq('test@example.com')
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