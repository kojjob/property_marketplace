require 'rails_helper'

RSpec.describe Property, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:property_images).dependent(:destroy) }
    it { should have_many(:favorites).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:property) }

    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_most(200) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:price) }
    it { should validate_numericality_of(:price).is_greater_than(0) }
    it { should validate_presence_of(:property_type) }
    it { should validate_inclusion_of(:property_type).in_array(Property::PROPERTY_TYPES) }
    it { should validate_numericality_of(:bedrooms).is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_numericality_of(:bathrooms).is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_numericality_of(:square_feet).is_greater_than(0).allow_nil }
    it { should validate_presence_of(:address) }
    it { should validate_presence_of(:city) }
    it { should validate_presence_of(:state) }
    it { should validate_presence_of(:zip_code) }
    it { should validate_inclusion_of(:status).in_array(Property::STATUSES) }
  end

  describe 'scopes' do
    let!(:active_property) { create(:property, status: 'active') }
    let!(:sold_property) { create(:property, :sold) }

    describe '.active' do
      it 'returns only active properties' do
        expect(Property.active).to include(active_property)
        expect(Property.active).not_to include(sold_property)
      end
    end

    describe '.recent' do
      it 'returns properties ordered by created_at desc' do
        Property.destroy_all  # Clear any existing properties
        old_property = create(:property, created_at: 2.days.ago)
        new_property = create(:property, created_at: 1.hour.ago)

        properties = Property.recent
        expect(properties.first.id).to eq(new_property.id)
        expect(properties.to_a.last.id).to eq(old_property.id)
      end
    end

    describe '.by_price' do
      let!(:cheap_property) { create(:property, price: 100_000) }
      let!(:expensive_property) { create(:property, price: 1_000_000) }

      it 'returns properties ordered by price ascending by default' do
        properties = Property.by_price
        expect(properties.first).to eq(cheap_property)
        expect(properties.last).to eq(expensive_property)
      end

      it 'returns properties ordered by price descending when specified' do
        properties = Property.by_price(:desc)
        expect(properties.first).to eq(expensive_property)
        expect(properties.last).to eq(cheap_property)
      end
    end
  end

  describe 'callbacks' do
    describe '#set_default_status' do
      it 'sets status to active when not provided' do
        property = build(:property, status: nil)
        property.valid?
        expect(property.status).to eq('active')
      end

      it 'does not override existing status' do
        property = build(:property, status: 'pending')
        property.valid?
        expect(property.status).to eq('pending')
      end
    end
  end

  describe 'business logic' do
    let(:property) { create(:property) }

    it 'can be favorited by users' do
      user = create(:user)
      favorite = create(:favorite, user: user, property: property)

      expect(property.favorites.count).to eq(1)
      expect(property.favorites.first.user).to eq(user)
    end

    it 'can have multiple images' do
      image1 = create(:property_image, property: property)
      image2 = create(:property_image, property: property)

      expect(property.property_images.count).to eq(2)
    end

    it 'destroys associated images when destroyed' do
      create(:property_image, property: property)

      expect { property.destroy }.to change { PropertyImage.count }.by(-1)
    end

    it 'destroys associated favorites when destroyed' do
      create(:favorite, property: property)

      expect { property.destroy }.to change { Favorite.count }.by(-1)
    end
  end
end