require 'rails_helper'

RSpec.describe Booking, type: :model do
  describe 'associations' do
    it { should belong_to(:listing) }
    it { should belong_to(:tenant).class_name('User').with_foreign_key('tenant_id') }
  end

  describe 'validations' do
    it { should validate_presence_of(:check_in_date) }
    it { should validate_presence_of(:check_out_date) }

    describe 'custom validations' do
      let(:listing) { create(:listing) }
      let(:user) { create(:user) }

      context '#check_out_after_check_in' do
        it 'is valid when check_out_date is after check_in_date' do
          booking = build(:booking,
                         listing: listing,
                         tenant: user,
                         check_in_date: Date.today,
                         check_out_date: Date.tomorrow)
          expect(booking).to be_valid
        end

        it 'is invalid when check_out_date is before check_in_date' do
          booking = build(:booking,
                         listing: listing,
                         tenant: user,
                         check_in_date: Date.tomorrow,
                         check_out_date: Date.today)
          expect(booking).not_to be_valid
          expect(booking.errors[:check_out_date]).to include("must be after check-in date")
        end

        it 'is invalid when check_out_date equals check_in_date' do
          booking = build(:booking,
                         listing: listing,
                         tenant: user,
                         check_in_date: Date.today,
                         check_out_date: Date.today)
          expect(booking).not_to be_valid
          expect(booking.errors[:check_out_date]).to include("must be after check-in date")
        end
      end

      context '#no_overlapping_bookings' do
        let!(:existing_booking) do
          create(:booking,
                listing: listing,
                check_in_date: 1.week.from_now,
                check_out_date: 2.weeks.from_now,
                status: 'confirmed')
        end

        it 'is valid when dates do not overlap' do
          booking = build(:booking,
                         listing: listing,
                         check_in_date: 3.weeks.from_now,
                         check_out_date: 4.weeks.from_now)
          expect(booking).to be_valid
        end

        it 'is invalid when dates overlap with existing booking' do
          booking = build(:booking,
                         listing: listing,
                         check_in_date: 10.days.from_now,
                         check_out_date: 15.days.from_now)
          expect(booking).not_to be_valid
          expect(booking.errors[:base]).to include("These dates overlap with an existing booking")
        end

        it 'is invalid when new booking contains existing booking' do
          booking = build(:booking,
                         listing: listing,
                         check_in_date: 5.days.from_now,
                         check_out_date: 3.weeks.from_now)
          expect(booking).not_to be_valid
          expect(booking.errors[:base]).to include("These dates overlap with an existing booking")
        end

        it 'is valid when existing booking is cancelled' do
          existing_booking.update(status: 'cancelled')
          booking = build(:booking,
                         listing: listing,
                         check_in_date: 10.days.from_now,
                         check_out_date: 15.days.from_now)
          expect(booking).to be_valid
        end

        it 'is valid when updating the same booking' do
          existing_booking.check_out_date = 16.days.from_now
          expect(existing_booking).to be_valid
        end
      end
    end
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(pending: 0, confirmed: 1, cancelled: 2, completed: 3) }
  end

  describe 'scopes' do
    let!(:past_booking) { create(:booking, check_in_date: 2.weeks.ago, check_out_date: 1.week.ago, status: 'completed') }
    let!(:current_booking) { create(:booking, check_in_date: 2.days.ago, check_out_date: 2.days.from_now, status: 'confirmed') }
    let!(:upcoming_booking) { create(:booking, check_in_date: 1.week.from_now, check_out_date: 2.weeks.from_now, status: 'confirmed') }

    describe '.upcoming' do
      it 'returns bookings with check_in_date in the future' do
        expect(Booking.upcoming).to include(upcoming_booking)
        expect(Booking.upcoming).not_to include(past_booking, current_booking)
      end
    end

    describe '.past' do
      it 'returns bookings with check_out_date in the past' do
        expect(Booking.past).to include(past_booking)
        expect(Booking.past).not_to include(current_booking, upcoming_booking)
      end
    end

    describe '.current' do
      it 'returns bookings that are currently active' do
        expect(Booking.current).to include(current_booking)
        expect(Booking.current).not_to include(past_booking, upcoming_booking)
      end
    end
  end
end