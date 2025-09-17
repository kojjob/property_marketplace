require 'rails_helper'

RSpec.describe BookingPaymentService, type: :service do
  let(:user) { create(:user) }
  let(:property) { create(:property) }
  let(:listing) { create(:listing, property: property) }
  let(:booking) { create(:booking, listing: listing, tenant: user, landlord: property.user, total_amount: 1000.00, status: 'confirmed') }

  describe '#call' do
    context 'with valid payment parameters' do
      let(:payment_params) do
        {
          amount_cents: 100000, # $1000.00
          payment_method_id: 'pm_test_visa',
          description: 'Booking payment for property rental'
        }
      end

      it 'creates a successful payment' do
        VCR.use_cassette('stripe_successful_payment') do
          result = described_class.new(booking, payment_params).call

          puts "Result error: #{result.error}" unless result.success?
          expect(result.success?).to be true
          expect(result.data[:payment]).to be_persisted
          expect(result.data[:payment].amount).to eq(1000.0)
          expect(result.data[:payment].status).to eq('completed')
        end
      end

      it 'updates booking payment status' do
        VCR.use_cassette('stripe_successful_payment') do
          result = described_class.new(booking, payment_params).call

          expect(result.success?).to be true
          booking.reload
          expect(booking.payment_status).to eq('paid')
        end
      end

      it 'creates payment record with correct attributes' do
        VCR.use_cassette('stripe_successful_payment') do
          result = described_class.new(booking, payment_params).call

          payment = result.data[:payment]
          expect(payment.booking).to eq(booking)
          expect(payment.payer).to eq(user)
          expect(payment.amount).to eq(1000.0)
          expect(payment.payment_type).to eq('full_payment')
        end
      end
    end

    context 'with invalid payment method' do
      let(:payment_params) do
        {
          amount_cents: 100000,
          payment_method_id: 'pm_card_visa_chargeDeclined',
          description: 'Booking payment for property rental'
        }
      end

      it 'returns failure with error message' do
        VCR.use_cassette('stripe_declined_payment') do
          result = described_class.new(booking, payment_params).call

          expect(result.success?).to be false
          expect(result.error).to include('declined')
        end
      end

      it 'does not update booking payment status' do
        VCR.use_cassette('stripe_declined_payment') do
          original_status = booking.payment_status
          result = described_class.new(booking, payment_params).call

          booking.reload
          expect(booking.payment_status).to eq(original_status)
        end
      end
    end

    context 'with insufficient amount' do
      let(:payment_params) do
        {
          amount_cents: 50000, # $500.00 (less than booking total)
          payment_method_id: 'pm_test_visa',
          description: 'Partial booking payment'
        }
      end

      it 'creates partial payment and updates status accordingly' do
        VCR.use_cassette('stripe_partial_payment') do
          result = described_class.new(booking, payment_params).call

          puts "Result error: #{result.error}" unless result.success?
          expect(result.success?).to be true
          booking.reload
          expect(booking.payment_status).to eq('partially_paid')
        end
      end
    end
  end

  describe '#calculate_fees' do
    it 'calculates platform fee correctly' do
      service = described_class.new(booking, {})
      fees = service.calculate_fees(100000) # $1000.00

      expect(fees[:platform_fee_cents]).to eq(5000) # 5% platform fee
      expect(fees[:processing_fee_cents]).to eq(300) # $3.00 processing fee
      expect(fees[:total_fees_cents]).to eq(5300)
    end
  end

  describe '#process_security_deposit' do
    let(:deposit_params) do
      {
        amount_cents: 50000, # $500.00 security deposit
        payment_method_id: 'pm_test_visa',
        hold_until: 30.days.from_now
      }
    end

    it 'creates a security deposit hold' do
      VCR.use_cassette('stripe_security_deposit_hold') do
        result = described_class.new(booking, deposit_params).process_security_deposit

        expect(result.success?).to be true
        expect(result.data[:deposit]).to be_persisted
        expect(result.data[:deposit].payment_type).to eq('security_deposit')
        expect(result.data[:deposit].status).to eq('completed')
      end
    end
  end
end