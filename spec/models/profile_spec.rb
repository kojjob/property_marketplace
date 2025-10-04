require 'rails_helper'

RSpec.describe Profile, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_one_attached(:avatar) }
  end

  describe 'validations' do
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:phone_number) }

    it { should allow_value('+1234567890').for(:phone_number) }
    it { should allow_value('555-123-4567').for(:phone_number) }
    it { should_not allow_value('invalid').for(:phone_number) }
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(tenant: 0, landlord: 1, agent: 2, admin: 3) }
    it { should define_enum_for(:verification_status).with_values(unverified: 0, pending: 1, verified: 2) }
  end

  describe 'methods' do
    let(:profile) { build(:profile, first_name: 'John', last_name: 'Doe') }

    describe '#full_name' do
      it 'returns the full name' do
        expect(profile.full_name).to eq('John Doe')
      end
    end

    describe '#display_name' do
      it 'returns full name when available' do
        expect(profile.display_name).to eq('John Doe')
      end

      it 'returns email when name is missing' do
        profile.first_name = nil
        profile.last_name = nil
        expect(profile.display_name).to eq(profile.user.email)
      end
    end

    describe '#verified?' do
      it 'returns true when status is verified' do
        profile.verification_status = 'verified'
        expect(profile).to be_verified
      end

      it 'returns false when status is not verified' do
        profile.verification_status = 'unverified'
        expect(profile).not_to be_verified
      end
    end

    describe '#can_list_property?' do
      it 'returns true for landlords' do
        profile.role = 'landlord'
        expect(profile.can_list_property?).to be true
      end

      it 'returns true for agents' do
        profile.role = 'agent'
        expect(profile.can_list_property?).to be true
      end

      it 'returns true for admins' do
        profile.role = 'admin'
        expect(profile.can_list_property?).to be true
      end

      it 'returns false for tenants' do
        profile.role = 'tenant'
        expect(profile.can_list_property?).to be false
      end
    end
  end

  describe 'scopes' do
    describe '.verified' do
      let!(:verified_profile) { create(:profile, verification_status: 'verified') }
      let!(:unverified_profile) { create(:profile, verification_status: 'unverified') }

      it 'returns only verified profiles' do
        expect(Profile.verified).to include(verified_profile)
        expect(Profile.verified).not_to include(unverified_profile)
      end
    end

    describe '.landlords' do
      let!(:landlord) { create(:profile, role: 'landlord') }
      let!(:tenant) { create(:profile, role: 'tenant') }

      it 'returns only landlord profiles' do
        expect(Profile.landlords).to include(landlord)
        expect(Profile.landlords).not_to include(tenant)
      end
    end
  end

  describe 'new profile fields' do
    let(:profile) { build(:profile) }

    it 'accepts company_name' do
      profile.company_name = 'ABC Realty'
      expect(profile.company_name).to eq('ABC Realty')
    end

    it 'accepts position' do
      profile.position = 'Senior Agent'
      expect(profile.position).to eq('Senior Agent')
    end

    it 'accepts years_experience' do
      profile.years_experience = 10
      expect(profile.years_experience).to eq(10)
    end

    it 'accepts languages' do
      profile.languages = 'English, Spanish'
      expect(profile.languages).to eq('English, Spanish')
    end

    it 'accepts address information' do
      profile.address = '123 Main St'
      profile.city = 'New York'
      profile.state = 'NY'
      profile.country = 'USA'

      expect(profile.address).to eq('123 Main St')
      expect(profile.city).to eq('New York')
      expect(profile.state).to eq('NY')
      expect(profile.country).to eq('USA')
    end

    it 'accepts website' do
      profile.website = 'https://johndoe.com'
      expect(profile.website).to eq('https://johndoe.com')
    end

    it 'accepts social media URLs' do
      profile.facebook_url = 'https://facebook.com/johndoe'
      profile.twitter_url = 'https://twitter.com/johndoe'
      profile.linkedin_url = 'https://linkedin.com/in/johndoe'
      profile.instagram_url = 'https://instagram.com/johndoe'

      expect(profile.facebook_url).to eq('https://facebook.com/johndoe')
      expect(profile.twitter_url).to eq('https://twitter.com/johndoe')
      expect(profile.linkedin_url).to eq('https://linkedin.com/in/johndoe')
      expect(profile.instagram_url).to eq('https://instagram.com/johndoe')
    end
  end

  describe 'avatar attachment' do
    it 'can attach an avatar' do
      profile = create(:profile)
      expect(profile.avatar).to_not be_attached

      # In a real test, you would attach a test image file
      # For now, we just test that the method exists and returns false when no avatar
      expect(profile.avatar.attached?).to be false
    end
  end
end
