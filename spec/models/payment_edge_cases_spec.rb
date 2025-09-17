require 'rails_helper'

RSpec.describe Payment, "Edge Cases", type: :model do
  describe 'Edge Case Scenarios' do
    let(:payer) { create(:user) }
    let(:payee) { create(:user) }
    let(:booking) { create(:booking, tenant: payer, total_amount: 1000.00, status: 'confirmed') }

    describe 'Boundary value testing' do
      context 'amount edge cases' do
        it 'rejects zero amount' do
          payment = build(:payment, amount: 0)
          expect(payment).not_to be_valid
          expect(payment.errors[:amount]).to include("must be greater than 0")
        end

        it 'rejects negative amount' do
          payment = build(:payment, amount: -100.00)
          expect(payment).not_to be_valid
        end

        it 'accepts very small positive amount' do
          payment = build(:payment, amount: 0.01)
          expect(payment).to be_valid
        end

        it 'handles very large amounts' do
          payment = build(:payment, amount: 999_999_999.99)
          expect(payment).to be_valid
        end

        it 'handles precise decimal amounts' do
          payment = build(:payment, amount: 123.456789)
          payment.valid?
          # Should be rounded to 2 decimal places
          expect(payment.amount).to eq(123.46)
        end
      end

      context 'service fee edge cases' do
        it 'accepts zero service fee' do
          payment = build(:payment, service_fee: 0)
          expect(payment).to be_valid
        end

        it 'rejects negative service fee' do
          payment = build(:payment, service_fee: -10.00)
          expect(payment).not_to be_valid
        end

        it 'allows service fee greater than amount' do
          # Edge case for high-fee scenarios
          payment = build(:payment, amount: 10.00, service_fee: 20.00)
          expect(payment).to be_valid
        end

        it 'handles nil service fee' do
          payment = build(:payment, service_fee: nil)
          expect(payment).to be_valid
          expect(payment.net_amount).to eq(payment.amount)
        end
      end
    end

    describe 'Race condition scenarios' do
      context 'concurrent payment processing' do
        it 'prevents double processing of same payment' do
          payment = create(:payment, status: 'pending')

          # Simulate concurrent processing attempts
          payment.update!(status: 'processing')

          # Second attempt should fail
          payment.reload
          expect(payment.status).to eq('processing')

          # Should not allow processing if already processing
          expect {
            payment.process_payment! if payment.status == 'processing'
          }.not_to change(payment, :status)
        end

        it 'prevents concurrent full payments for same booking' do
          # Create first payment
          payment1 = create(:payment,
                           booking: booking,
                           payment_type: 'full_payment',
                           amount: 1000.00,
                           status: 'completed')

          # Attempt to create second full payment
          payment2 = build(:payment,
                          booking: booking,
                          payment_type: 'full_payment',
                          amount: 1000.00)

          expect(payment2).not_to be_valid
          expect(payment2.errors[:booking]).to include("already has a full payment")
        end
      end

      context 'booking status changes during payment' do
        it 'handles booking cancellation during payment processing' do
          payment = create(:payment, booking: booking, status: 'pending')

          # Booking gets cancelled during payment processing
          booking.update!(status: 'cancelled')

          # Payment validation should catch this
          payment.reload
          expect(payment.valid?).to be false
          expect(payment.errors[:booking]).to include("must be confirmed or completed for payment")
        end

        it 'handles booking completion during payment' do
          payment = create(:payment, booking: booking, status: 'pending')

          # Booking gets completed
          booking.update!(status: 'completed')

          # Payment should still be valid
          payment.reload
          expect(payment.valid?).to be true
        end
      end
    end

    describe 'Null and empty value handling' do
      it 'handles nil booking gracefully' do
        payment = build(:payment, booking: nil)
        expect(payment).not_to be_valid
        expect(payment.errors[:booking]).to include("must exist")
      end

      it 'handles nil payer gracefully' do
        payment = build(:payment, payer: nil)
        expect(payment).not_to be_valid
        expect(payment.errors[:payer]).to include("must exist")
      end

      it 'handles nil payee gracefully' do
        payment = build(:payment, payee: nil)
        expect(payment).not_to be_valid
        expect(payment.errors[:payee]).to include("must exist")
      end

      it 'handles empty transaction_id on new record' do
        payment = build(:payment)
        expect(payment.transaction_id).to be_nil
        payment.save!
        expect(payment.transaction_id).to be_present
      end

      it 'handles nil payment_method' do
        payment = build(:payment, payment_method: nil)
        expect(payment).to be_valid # payment_method is optional
      end
    end

    describe 'Currency edge cases' do
      it 'handles various valid currency codes' do
        %w[USD EUR GBP JPY CNY AUD CAD].each do |currency|
          payment = build(:payment, currency: currency)
          expect(payment).to be_valid
        end
      end

      it 'validates currency code format' do
        payment = build(:payment, currency: 'US')
        expect(payment).not_to be_valid
        expect(payment.errors[:currency]).to include("must be a 3-letter ISO code")
      end

      it 'rejects invalid currency codes' do
        payment = build(:payment, currency: 'XXX')
        expect(payment).not_to be_valid
        expect(payment.errors[:currency]).to include("is not a valid currency")
      end

      it 'handles case sensitivity in currency codes' do
        payment = build(:payment, currency: 'usd')
        payment.valid?
        expect(payment.currency).to eq('USD') # Should be uppercase
      end

      it 'preserves currency through updates' do
        payment = create(:payment, currency: 'EUR')
        payment.update!(amount: 200.00)
        expect(payment.currency).to eq('EUR')
      end
    end

    describe 'Transaction ID edge cases' do
      it 'generates unique transaction IDs' do
        payments = create_list(:payment, 100)
        transaction_ids = payments.map(&:transaction_id)
        expect(transaction_ids.uniq.count).to eq(100)
      end

      it 'handles transaction ID format correctly' do
        payment = create(:payment)
        expect(payment.transaction_id).to match(/^PAY-[A-Z0-9]{10}$/)
      end

      it 'prevents manual transaction ID modification after creation' do
        payment = create(:payment)
        original_id = payment.transaction_id
        payment.update!(transaction_id: 'CUSTOM-ID')
        expect(payment.reload.transaction_id).to eq(original_id)
      end
    end

    describe 'Refund edge cases' do
      let(:payment) { create(:payment, status: 'completed', amount: 1000.00) }

      it 'prevents refund greater than original amount' do
        expect {
          payment.process_refund!(1500.00)
        }.to raise_error(StandardError, "Refund amount cannot exceed payment amount")
      end

      it 'handles multiple partial refunds' do
        refund1 = payment.process_refund!(300.00)
        expect(refund1.amount).to eq(300.00)

        refund2 = payment.process_refund!(200.00)
        expect(refund2.amount).to eq(200.00)

        # Total refunded: 500.00, remaining: 500.00
        expect(payment.reload.total_refunded).to eq(500.00)
      end

      it 'prevents refunding more than remaining amount' do
        payment.process_refund!(700.00)

        expect {
          payment.process_refund!(400.00)
        }.to raise_error(StandardError, "Refund amount exceeds remaining refundable amount")
      end

      it 'handles zero refund amount' do
        expect {
          payment.process_refund!(0)
        }.to raise_error(StandardError, "Refund amount must be greater than 0")
      end

      it 'handles refund on failed payment' do
        failed_payment = create(:payment, status: 'failed')
        expect {
          failed_payment.process_refund!
        }.to raise_error(StandardError, "Payment cannot be refunded")
      end
    end

    describe 'Payment method edge cases' do
      it 'handles all payment method types' do
        %w[credit_card debit_card bank_transfer paypal stripe cash other].each do |method|
          payment = build(:payment, payment_method: method)
          expect(payment).to be_valid
        end
      end

      it 'processes cash payments differently' do
        payment = create(:payment, payment_method: 'cash', status: 'pending')

        # Cash payments might skip processing state
        payment.process_payment!
        expect(payment.status).to eq('completed')
        expect(payment.processed_at).to be_present
      end
    end

    describe 'Date and time edge cases' do
      context 'payment timing' do
        it 'handles payments at exact booking start' do
          booking.update!(check_in: Date.today, check_out: Date.tomorrow)
          payment = build(:payment, booking: booking)
          expect(payment).to be_valid
        end

        it 'handles payments after booking ends' do
          booking.update!(check_in: 1.month.ago, check_out: 3.weeks.ago)
          payment = build(:payment, booking: booking)
          expect(payment).to be_valid # Late payments are allowed
        end

        it 'records accurate processing timestamps' do
          payment = create(:payment, status: 'pending')

          Timecop.freeze(Time.current) do
            payment.process_payment!
            expect(payment.processed_at).to eq(Time.current)
          end
        end

        it 'handles daylight saving time transitions' do
          # Create payment just before DST change
          Timecop.travel(Time.zone.parse("2024-03-10 01:59:00")) do
            payment = create(:payment)

            # Process after DST change (clocks spring forward)
            Timecop.travel(1.hour.from_now) do
              payment.process_payment!
              expect(payment.processed_at).to be_present
            end
          end
        end
      end
    end

    describe 'Status transition edge cases' do
      it 'handles all valid status transitions' do
        payment = create(:payment, status: 'pending')

        # Pending -> Processing
        payment.update!(status: 'processing')
        expect(payment.status).to eq('processing')

        # Processing -> Completed
        payment.update!(status: 'completed')
        expect(payment.status).to eq('completed')

        # Completed -> Refunded
        payment.update!(status: 'refunded')
        expect(payment.status).to eq('refunded')
      end

      it 'prevents invalid status transitions' do
        payment = create(:payment, status: 'cancelled')

        # Should not allow cancelled -> completed
        payment.status = 'completed'
        expect(payment.valid?).to be false
      end

      it 'maintains data integrity during status changes' do
        payment = create(:payment, status: 'pending', amount: 100.00)
        original_amount = payment.amount

        payment.update!(status: 'completed')
        expect(payment.amount).to eq(original_amount)
        expect(payment.payer).to be_present
        expect(payment.payee).to be_present
      end
    end

    describe 'Calculation edge cases' do
      context 'total payment calculations' do
        it 'handles booking with no payments' do
          empty_booking = create(:booking, total_amount: 500.00)
          expect(empty_booking.total_paid).to eq(0)
        end

        it 'calculates total with mixed payment statuses' do
          create(:payment, booking: booking, amount: 200.00, status: 'completed')
          create(:payment, booking: booking, amount: 300.00, status: 'pending')
          create(:payment, booking: booking, amount: 100.00, status: 'failed')

          expect(booking.total_paid).to eq(200.00) # Only completed payments
        end

        it 'handles refunds in total calculations' do
          create(:payment, booking: booking, amount: 1000.00, status: 'completed')
          create(:payment, booking: booking, amount: -200.00, payment_type: 'refund', status: 'completed')

          expect(booking.total_paid).to eq(800.00)
        end
      end

      context 'net amount calculations' do
        it 'handles very small service fees' do
          payment = create(:payment, amount: 100.00, service_fee: 0.01)
          expect(payment.net_amount).to eq(99.99)
        end

        it 'handles service fee equal to amount' do
          payment = create(:payment, amount: 50.00, service_fee: 50.00)
          expect(payment.net_amount).to eq(0)
        end

        it 'handles service fee greater than amount' do
          payment = create(:payment, amount: 30.00, service_fee: 50.00)
          expect(payment.net_amount).to eq(-20.00)
        end
      end
    end

    describe 'Concurrent modification edge cases' do
      it 'handles optimistic locking for payment updates' do
        payment1 = create(:payment, status: 'pending')
        payment2 = Payment.find(payment1.id)

        payment1.update!(status: 'processing')

        # Second update should detect stale object
        expect {
          payment2.update!(status: 'failed')
        }.to raise_error(ActiveRecord::StaleObjectError)
      end
    end

    describe 'Security edge cases' do
      it 'prevents SQL injection in transaction ID search' do
        malicious_id = "PAY-ABC'; DROP TABLE payments; --"
        expect {
          Payment.where(transaction_id: malicious_id).first
        }.not_to raise_error
        expect(Payment.table_exists?).to be true
      end

      it 'sanitizes currency input' do
        payment = build(:payment, currency: "<script>alert('XSS')</script>")
        payment.valid?
        expect(payment.errors[:currency]).to be_present
      end

      it 'handles very long transaction reference' do
        payment = build(:payment, transaction_reference: 'A' * 1000)
        expect(payment).to be_valid
        # Should truncate or handle gracefully
      end
    end
  end
end
