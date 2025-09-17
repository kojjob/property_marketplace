require 'rails_helper'

RSpec.describe Payment::SubscriptionService, type: :service do
  let(:user) { create(:user) }
  let(:property) { create(:property) }
  let(:listing) { create(:listing, property: property, listing_type: 'subscription', price: 500.00) }
  let(:booking) { create(:booking, listing: listing, tenant: user, landlord: property.user, total_amount: 500.00, status: 'confirmed') }

  describe '#call' do
    context 'with valid subscription parameters' do
      let(:subscription_params) do
        {
          payment_method_id: 'pm_test_visa',
          price_id: 'price_test_subscription',
          trial_period_days: 7
        }
      end

      it 'creates a successful subscription' do
        VCR.use_cassette('stripe_subscription_creation') do
          result = described_class.new(booking, subscription_params).call

          puts "Result error: #{result.error}" unless result.success?
          expect(result.success?).to be true
          expect(result.data[:subscription]).to be_present
          expect(result.data[:subscription].name).to eq('Property Subscription')
          expect(result.data[:subscription].status).to eq('active')
        end
      end

      it 'creates initial payment record' do
        VCR.use_cassette('stripe_subscription_creation') do
          result = described_class.new(booking, subscription_params).call

          payment = Payment.where(booking: booking, payment_type: 'subscription').first
          expect(payment).to be_present
          expect(payment.amount).to eq(500.0)
          expect(payment.status).to eq('completed')
        end
      end

      it 'updates booking status to active subscription' do
        VCR.use_cassette('stripe_subscription_creation') do
          result = described_class.new(booking, subscription_params).call

          booking.reload
          expect(booking.payment_status).to eq('paid')
          expect(booking.status).to eq('confirmed')
        end
      end
    end

    context 'with invalid payment method' do
      let(:subscription_params) do
        {
          payment_method_id: 'pm_card_visa_chargeDeclined',
          price_id: 'price_test_subscription'
        }
      end

      it 'returns failure with error message' do
        VCR.use_cassette('stripe_subscription_failed') do
          result = described_class.new(booking, subscription_params).call

          expect(result.success?).to be false
          expect(result.error).to include('declined')
        end
      end
    end
  end

  describe '#cancel_subscription' do
    let(:subscription_params) do
      {
        payment_method_id: 'pm_test_visa',
        price_id: 'price_test_subscription'
      }
    end

    before do
      VCR.use_cassette('stripe_subscription_creation') do
        @result = described_class.new(booking, subscription_params).call
        @subscription = @result.data[:subscription]
      end
    end

    it 'cancels the subscription successfully' do
      VCR.use_cassette('stripe_subscription_cancellation') do
        service = described_class.new(booking, {})
        result = service.cancel_subscription(@subscription.processor_id)

        expect(result.success?).to be true
        expect(result.data[:subscription].status).to eq('canceled')
      end
    end

    it 'creates cancellation payment record' do
      VCR.use_cassette('stripe_subscription_cancellation') do
        service = described_class.new(booking, {})
        result = service.cancel_subscription(@subscription.processor_id)

        cancellation_payment = Payment.where(
          booking: booking,
          payment_type: 'refund'
        ).last

        expect(cancellation_payment).to be_present
      end
    end
  end

  describe '#update_subscription' do
    let(:subscription_params) do
      {
        payment_method_id: 'pm_test_visa',
        price_id: 'price_test_subscription'
      }
    end

    let(:update_params) do
      {
        price_id: 'price_test_subscription_updated',
        prorate: true
      }
    end

    before do
      VCR.use_cassette('stripe_subscription_creation') do
        @result = described_class.new(booking, subscription_params).call
        @subscription = @result.data[:subscription]
      end
    end

    it 'updates the subscription successfully' do
      VCR.use_cassette('stripe_subscription_update') do
        service = described_class.new(booking, {})
        result = service.update_subscription(@subscription.processor_id, update_params)

        expect(result.success?).to be true
        expect(result.data[:subscription]).to be_present
      end
    end
  end
end