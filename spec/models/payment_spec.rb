require 'rails_helper'

RSpec.describe Payment, type: :model do
  describe 'associations' do
    it { should belong_to(:booking) }
    it { should belong_to(:payer).class_name('User').with_foreign_key('payer_id') }
    it { should belong_to(:payee).class_name('User').with_foreign_key('payee_id') }
  end

  describe 'validations' do
    subject { build(:payment) }

    it { should validate_presence_of(:amount) }

    it 'validates amount is greater than 0' do
      payment = build(:payment, amount: 0)
      expect(payment).not_to be_valid
      expect(payment.errors[:amount]).to include("must be greater than 0")

      payment = build(:payment, amount: 100)
      expect(payment).to be_valid
    end

    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:payment_type) }

    it 'validates currency presence' do
      payment = Payment.new(amount: 100, status: 'pending', payment_type: 'deposit')
      payment.currency = nil
      payment.send(:set_default_currency) # This should set USD
      expect(payment.currency).to eq('USD')
    end

    describe 'custom validations' do
      context '#payer_and_payee_different' do
        let(:user) { create(:user) }
        let(:booking) { create(:booking) }

        it 'prevents payments to self' do
          payment = build(:payment, booking: booking, payer: user, payee: user)
          expect(payment).not_to be_valid
          expect(payment.errors[:payee]).to include("can't be the same as payer")
        end

        it 'allows payments between different users' do
          payer = create(:user)
          payee = create(:user)
          payment = build(:payment, booking: booking, payer: payer, payee: payee)
          expect(payment).to be_valid
        end
      end

      context '#amount_matches_booking' do
        let(:booking) { create(:booking, total_amount: 1000.00) }

        it 'validates initial payment matches booking total for full payment' do
          payment = build(:payment,
                          booking: booking,
                          payment_type: 'full_payment',
                          amount: 500.00)
          expect(payment).not_to be_valid
          expect(payment.errors[:amount]).to include("must match booking total for full payment")
        end

        it 'allows correct full payment amount' do
          payment = build(:payment,
                          booking: booking,
                          payment_type: 'full_payment',
                          amount: 1000.00)
          expect(payment).to be_valid
        end

        it 'allows deposit to be less than total' do
          payment = build(:payment,
                          booking: booking,
                          payment_type: 'deposit',
                          amount: 200.00)
          expect(payment).to be_valid
        end
      end

      context '#no_duplicate_payment' do
        let(:booking) { create(:booking, total_amount: 1000.00) }

        it 'prevents multiple full payments for same booking' do
          create(:payment, booking: booking, payment_type: 'full_payment', amount: 1000.00)
          duplicate = build(:payment, booking: booking, payment_type: 'full_payment', amount: 1000.00)
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:booking]).to include("already has a full payment")
        end

        it 'allows multiple partial payments' do
          create(:payment, booking: booking, payment_type: 'deposit', amount: 200.00)
          second_payment = build(:payment, booking: booking, payment_type: 'final_payment', amount: 800.00)
          expect(second_payment).to be_valid
        end
      end

      context '#booking_status_appropriate' do
        it 'prevents payments on cancelled bookings' do
          booking = create(:booking, status: 'cancelled')
          payment = build(:payment, booking: booking)
          expect(payment).not_to be_valid
          expect(payment.errors[:booking]).to include("must be confirmed or completed for payment")
        end

        it 'allows payments on confirmed bookings' do
          booking = create(:booking, status: 'confirmed')
          payment = build(:payment, booking: booking)
          expect(payment).to be_valid
        end

        it 'allows payments on completed bookings' do
          booking = create(:booking, status: 'completed')
          payment = build(:payment, booking: booking)
          expect(payment).to be_valid
        end
      end
    end
  end

  describe 'enums' do
    it { should define_enum_for(:status)
          .with_values(
            pending: 0,
            processing: 1,
            completed: 2,
            failed: 3,
            refunded: 4,
            cancelled: 5
          ) }

    it { should define_enum_for(:payment_type)
          .with_values(
            deposit: 0,
            full_payment: 1,
            final_payment: 2,
            refund: 3,
            security_deposit: 4,
            additional_fee: 5
          ) }

    it { should define_enum_for(:payment_method)
          .with_values(
            credit_card: 0,
            debit_card: 1,
            bank_transfer: 2,
            paypal: 3,
            stripe: 4,
            cash: 5,
            other: 6
          ) }
  end

  describe 'scopes' do
    let!(:completed_payment) { create(:payment, status: 'completed') }
    let!(:pending_payment) { create(:payment, status: 'pending') }
    let!(:failed_payment) { create(:payment, status: 'failed') }
    let!(:recent_payment) { create(:payment, created_at: 1.day.ago) }
    let!(:old_payment) { create(:payment, created_at: 2.months.ago) }

    describe '.successful' do
      it 'returns only completed payments' do
        expect(Payment.successful).to include(completed_payment)
        expect(Payment.successful).not_to include(pending_payment, failed_payment)
      end
    end

    describe '.pending' do
      it 'returns only pending payments' do
        expect(Payment.pending).to include(pending_payment)
        expect(Payment.pending).not_to include(completed_payment, failed_payment)
      end
    end

    describe '.failed' do
      it 'returns only failed payments' do
        expect(Payment.failed).to include(failed_payment)
        expect(Payment.failed).not_to include(completed_payment, pending_payment)
      end
    end

    describe '.recent' do
      it 'returns payments from last 30 days' do
        expect(Payment.recent).to include(recent_payment)
        expect(Payment.recent).not_to include(old_payment)
      end
    end

    describe '.for_booking' do
      let(:booking) { create(:booking) }
      let!(:booking_payment) { create(:payment, booking: booking) }
      let!(:other_payment) { create(:payment) }

      it 'returns payments for specific booking' do
        expect(Payment.for_booking(booking.id)).to include(booking_payment)
        expect(Payment.for_booking(booking.id)).not_to include(other_payment)
      end
    end
  end

  describe 'methods' do
    describe '#process_payment!' do
      let(:payment) { create(:payment, status: 'pending') }

      context 'when payment is successful' do
        before do
          allow(payment).to receive(:charge_payment_method).and_return(true)
        end

        it 'updates status to completed' do
          payment.process_payment!
          expect(payment.status).to eq('completed')
        end

        it 'sets processed_at timestamp' do
          payment.process_payment!
          expect(payment.processed_at).to be_present
        end

        it 'returns true' do
          expect(payment.process_payment!).to be true
        end
      end

      context 'when payment fails' do
        before do
          allow(payment).to receive(:charge_payment_method).and_return(false)
        end

        it 'updates status to failed' do
          payment.process_payment!
          expect(payment.status).to eq('failed')
        end

        it 'returns false' do
          expect(payment.process_payment!).to be false
        end
      end
    end

    describe '#refundable?' do
      it 'returns true for completed payments' do
        payment = build(:payment, status: 'completed')
        expect(payment.refundable?).to be true
      end

      it 'returns false for pending payments' do
        payment = build(:payment, status: 'pending')
        expect(payment.refundable?).to be false
      end

      it 'returns false for already refunded payments' do
        payment = build(:payment, status: 'refunded')
        expect(payment.refundable?).to be false
      end
    end

    describe '#process_refund!' do
      let(:payment) { create(:payment, status: 'completed', amount: 500.00, payment_type: 'deposit') }

      context 'with full refund' do
        it 'creates refund payment record' do
          refund = nil
          expect {
            refund = payment.process_refund!
          }.to change(Payment, :count)

          expect(refund).to be_a(Payment)
          expect(refund.payment_type).to eq('refund')
        end

        it 'sets correct refund amount' do
          refund = payment.process_refund!
          expect(refund.amount).to eq(500.00)
        end

        it 'sets payment type to refund' do
          refund = payment.process_refund!
          expect(refund.payment_type).to eq('refund')
        end

        it 'updates original payment status' do
          payment.process_refund!
          expect(payment.reload.status).to eq('refunded')
        end
      end

      context 'with partial refund' do
        it 'creates refund with specified amount' do
          refund = payment.process_refund!(200.00)
          expect(refund.amount).to eq(200.00)
        end

        it 'does not mark original as fully refunded for partial' do
          payment.process_refund!(200.00)
          expect(payment.reload.status).to eq('completed')
        end
      end

      context 'when payment is not refundable' do
        let(:payment) { create(:payment, status: 'pending') }

        it 'raises error' do
          expect {
            payment.process_refund!
          }.to raise_error(StandardError, "Payment cannot be refunded")
        end
      end
    end

    describe '#net_amount' do
      let(:payment) { create(:payment, amount: 1000.00, service_fee: 50.00) }

      it 'calculates amount minus service fee' do
        expect(payment.net_amount).to eq(950.00)
      end

      it 'returns full amount if no service fee' do
        payment.service_fee = nil
        expect(payment.net_amount).to eq(1000.00)
      end
    end

    describe '#formatted_amount' do
      it 'formats USD currency correctly' do
        payment = build(:payment, amount: 1234.56, currency: 'USD')
        expect(payment.formatted_amount).to eq('$1,234.56')
      end

      it 'formats EUR currency correctly' do
        payment = build(:payment, amount: 1234.56, currency: 'EUR')
        expect(payment.formatted_amount).to eq('€1,234.56')
      end

      it 'formats GBP currency correctly' do
        payment = build(:payment, amount: 1234.56, currency: 'GBP')
        expect(payment.formatted_amount).to eq('£1,234.56')
      end
    end
  end

  describe 'callbacks' do
    describe '#set_default_currency' do
      it 'sets USD as default currency if not provided' do
        payment = Payment.new(
          amount: 100.00,
          payment_type: 'deposit',
          status: 'pending'
        )
        payment.valid?
        expect(payment.currency).to eq('USD')
      end

      it 'preserves specified currency' do
        payment = Payment.new(
          amount: 100.00,
          payment_type: 'deposit',
          status: 'pending',
          currency: 'EUR'
        )
        payment.valid?
        expect(payment.currency).to eq('EUR')
      end
    end

    describe '#generate_transaction_id' do
      it 'generates unique transaction ID on create' do
        payment = create(:payment)
        expect(payment.transaction_id).to be_present
        expect(payment.transaction_id).to match(/^PAY-[A-Z0-9]{10}$/)
      end

      it 'does not change transaction ID on update' do
        payment = create(:payment)
        original_id = payment.transaction_id
        payment.update!(amount: 200.00)
        expect(payment.transaction_id).to eq(original_id)
      end
    end

    describe '#update_booking_payment_status' do
      let(:booking) { create(:booking, total_amount: 1000.00) }

      it 'updates booking to paid when full payment completed' do
        payment = create(:payment,
                        booking: booking,
                        payment_type: 'full_payment',
                        amount: 1000.00,
                        status: 'completed')

        expect(booking.reload.payment_status).to eq('paid')
      end

      it 'updates booking to partially_paid for deposit' do
        payment = create(:payment,
                        booking: booking,
                        payment_type: 'deposit',
                        amount: 200.00,
                        status: 'completed')

        expect(booking.reload.payment_status).to eq('partially_paid')
      end
    end
  end
end