require 'rails_helper'

RSpec.describe Webhooks::StripeController, type: :controller do
  let(:valid_signature) { 'test_signature' }
  let(:invalid_signature) { 'invalid_signature' }

  before do
    allow(Stripe::Webhook).to receive(:construct_event).and_return(stripe_event)
  end

  describe 'POST #create' do
    context 'with valid webhook signature' do
      context 'payment_intent.succeeded event' do
        let(:stripe_event) do
          {
            'type' => 'payment_intent.succeeded',
            'data' => {
              'object' => {
                'id' => 'pi_test123',
                'amount' => 100000,
                'currency' => 'usd',
                'status' => 'succeeded',
                'metadata' => {
                  'booking_id' => '123'
                }
              }
            }
          }
        end

        it 'processes payment success' do
          request.headers['Stripe-Signature'] = valid_signature
          post :create, body: stripe_event.to_json

          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['status']).to eq('success')
        end

        it 'updates payment record status' do
          booking = create(:booking, id: 123, status: 'confirmed')
          payment = create(:payment, booking: booking, transaction_reference: 'pi_test123', status: 'pending')

          request.headers['Stripe-Signature'] = valid_signature
          post :create, body: stripe_event.to_json

          payment.reload
          expect(payment.status).to eq('completed')
        end
      end

      context 'payment_intent.payment_failed event' do
        let(:stripe_event) do
          {
            'type' => 'payment_intent.payment_failed',
            'data' => {
              'object' => {
                'id' => 'pi_test123',
                'amount' => 100000,
                'currency' => 'usd',
                'status' => 'requires_payment_method',
                'last_payment_error' => {
                  'message' => 'Your card was declined.'
                },
                'metadata' => {
                  'booking_id' => '123'
                }
              }
            }
          }
        end

        it 'processes payment failure' do
          request.headers['Stripe-Signature'] = valid_signature
          post :create, body: stripe_event.to_json

          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['status']).to eq('success')
        end

        it 'updates payment record to failed' do
          booking = create(:booking, id: 123, status: 'confirmed')
          payment = create(:payment, booking: booking, transaction_reference: 'pi_test123', status: 'pending')

          request.headers['Stripe-Signature'] = valid_signature
          post :create, body: stripe_event.to_json

          payment.reload
          expect(payment.status).to eq('failed')
          expect(payment.failure_reason).to eq('Your card was declined.')
        end
      end

      context 'invoice.payment_succeeded event' do
        let(:stripe_event) do
          {
            'type' => 'invoice.payment_succeeded',
            'data' => {
              'object' => {
                'id' => 'in_test123',
                'subscription' => 'sub_test123',
                'amount_paid' => 50000,
                'currency' => 'usd',
                'status' => 'paid',
                'metadata' => {
                  'booking_id' => '123'
                }
              }
            }
          }
        end

        it 'processes subscription payment success' do
          request.headers['Stripe-Signature'] = valid_signature
          post :create, body: stripe_event.to_json

          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['status']).to eq('success')
        end

        it 'creates recurring payment record' do
          booking = create(:booking, id: 123, status: 'confirmed')

          request.headers['Stripe-Signature'] = valid_signature
          post :create, body: stripe_event.to_json

          payment = Payment.where(
            booking: booking,
            transaction_reference: 'in_test123',
            payment_type: 'subscription'
          ).last

          expect(payment).to be_present
          expect(payment.amount).to eq(500.0)
          expect(payment.status).to eq('completed')
        end
      end

      context 'customer.subscription.deleted event' do
        let(:stripe_event) do
          {
            'type' => 'customer.subscription.deleted',
            'data' => {
              'object' => {
                'id' => 'sub_test123',
                'status' => 'canceled',
                'metadata' => {
                  'booking_id' => '123'
                }
              }
            }
          }
        end

        it 'processes subscription cancellation' do
          request.headers['Stripe-Signature'] = valid_signature
          post :create, body: stripe_event.to_json

          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['status']).to eq('success')
        end
      end

      context 'unhandled event type' do
        let(:stripe_event) do
          {
            'type' => 'account.updated',
            'data' => {
              'object' => {
                'id' => 'acct_test123'
              }
            }
          }
        end

        it 'returns success for unhandled events' do
          request.headers['Stripe-Signature'] = valid_signature
          post :create, body: stripe_event.to_json

          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['status']).to eq('ignored')
        end
      end
    end

    context 'with invalid webhook signature' do
      let(:stripe_event) { { 'type' => 'payment_intent.succeeded' } }

      before do
        allow(Stripe::Webhook).to receive(:construct_event).and_raise(
          Stripe::SignatureVerificationError.new("Invalid signature", "sig_test")
        )
      end

      it 'returns unauthorized' do
        request.headers['Stripe-Signature'] = invalid_signature
        post :create, body: stripe_event.to_json

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to include('Invalid signature')
      end
    end
  end
end
