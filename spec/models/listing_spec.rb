require 'rails_helper'

RSpec.describe Listing, type: :model do
  describe 'associations' do
    it { should belong_to(:property) }
    it { should belong_to(:user) }
    it { should have_many(:bookings).dependent(:destroy) }
    it { should have_many(:listing_amenities).dependent(:destroy) }
    it { should have_many(:amenities).through(:listing_amenities) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:price) }
    it { should validate_numericality_of(:price).is_greater_than(0) }
    it { should validate_presence_of(:listing_type) }
    it { should validate_presence_of(:status) }

    context 'for rental listings' do
      subject { build(:listing, listing_type: 'rent') }

      it { should validate_presence_of(:lease_duration) }
      it { should validate_numericality_of(:lease_duration).is_greater_than(0) }
    end
  end

  describe 'enums' do
    it { should define_enum_for(:listing_type).with_values(rent: 0, sale: 1, short_term: 2, subscription: 3) }
    it { should define_enum_for(:status).with_values(draft: 0, active: 1, inactive: 2, archived: 3) }
    it { should define_enum_for(:lease_duration_unit).with_values(days: 0, weeks: 1, months: 2, years: 3) }
  end

  describe 'scopes' do
    describe '.active' do
      let!(:active_listing) { create(:listing, status: 'active') }
      let!(:inactive_listing) { create(:listing, status: 'inactive') }

      it 'returns only active listings' do
        expect(Listing.active).to include(active_listing)
        expect(Listing.active).not_to include(inactive_listing)
      end
    end

    describe '.available' do
      let!(:available_listing) { create(:listing, status: 'active', available_from: 1.day.ago) }
      let!(:future_listing) { create(:listing, status: 'active', available_from: 1.week.from_now) }

      it 'returns listings available now' do
        expect(Listing.available).to include(available_listing)
        expect(Listing.available).not_to include(future_listing)
      end
    end

    describe '.by_type' do
      let!(:rental) { create(:listing, listing_type: 'rent') }
      let!(:sale) { create(:listing, listing_type: 'sale') }

      it 'filters by listing type' do
        expect(Listing.by_type('rent')).to include(rental)
        expect(Listing.by_type('rent')).not_to include(sale)
      end
    end

    describe '.price_between' do
      let!(:cheap_listing) { create(:listing, price: 1000) }
      let!(:mid_listing) { create(:listing, price: 2000) }
      let!(:expensive_listing) { create(:listing, price: 3000) }

      it 'returns listings in price range' do
        results = Listing.price_between(1500, 2500)
        expect(results).to include(mid_listing)
        expect(results).not_to include(cheap_listing)
        expect(results).not_to include(expensive_listing)
      end
    end
  end

  describe 'methods' do
    let(:listing) { build(:listing) }

    describe '#available?' do
      it 'returns true when active and available date has passed' do
        listing.status = 'active'
        listing.available_from = 1.day.ago
        expect(listing).to be_available
      end

      it 'returns false when inactive' do
        listing.status = 'inactive'
        listing.available_from = 1.day.ago
        expect(listing).not_to be_available
      end

      it 'returns false when available date is in future' do
        listing.status = 'active'
        listing.available_from = 1.day.from_now
        expect(listing).not_to be_available
      end
    end

    describe '#monthly_price' do
      context 'when listing is for rent' do
        it 'returns the price for monthly leases' do
          listing = build(:listing, listing_type: 'rent', price: 2000, lease_duration_unit: 'months')
          expect(listing.monthly_price).to eq(2000)
        end

        it 'calculates monthly price for weekly leases' do
          listing = build(:listing, listing_type: 'rent', price: 500, lease_duration_unit: 'weeks')
          expect(listing.monthly_price).to be_within(0.01).of(2166.67)
        end

        it 'calculates monthly price for yearly leases' do
          listing = build(:listing, listing_type: 'rent', price: 24000, lease_duration_unit: 'years')
          expect(listing.monthly_price).to eq(2000)
        end
      end

      context 'when listing is for sale' do
        it 'returns nil' do
          listing = build(:listing, listing_type: 'sale', price: 500000)
          expect(listing.monthly_price).to be_nil
        end
      end
    end

    describe '#can_be_booked?' do
      it 'returns true when available and no overlapping bookings' do
        listing = create(:listing, :active)
        expect(listing.can_be_booked?(1.week.from_now, 2.weeks.from_now)).to be true
      end

      it 'returns false when there are overlapping bookings' do
        listing = create(:listing, :active)
        create(:booking, listing: listing,
               check_in_date: 1.week.from_now,
               check_out_date: 2.weeks.from_now,
               status: 'confirmed')

        expect(listing.can_be_booked?(10.days.from_now, 15.days.from_now)).to be false
      end
    end
  end
end