require 'rails_helper'

RSpec.describe Profile, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
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
end