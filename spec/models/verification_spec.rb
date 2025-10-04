require 'rails_helper'

RSpec.describe Verification, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:verified_by).class_name('User').optional }
  end

  describe 'validations' do
    subject { build(:verification) }

    it { should validate_presence_of(:verification_type) }
    it { should validate_presence_of(:status) }

    describe 'document validation' do
      it 'validates document presence for certain verification types' do
        verification = build(:verification, verification_type: 'identity', document_url: nil)
        expect(verification).not_to be_valid
        expect(verification.errors[:document_url]).to include("is required for identity verification")
      end

      it 'does not require document for email verification' do
        verification = build(:verification, verification_type: 'email', document_url: nil)
        expect(verification).to be_valid
      end
    end
  end

  describe 'enums' do
    it { should define_enum_for(:verification_type)
          .with_values(
            email: 0,
            phone: 1,
            identity: 2,
            address: 3,
            background_check: 4,
            income: 5
          ) }

    it { should define_enum_for(:status)
          .with_values(
            pending: 0,
            in_review: 1,
            approved: 2,
            rejected: 3,
            expired: 4
          ) }
  end

  describe 'scopes' do
    let!(:pending_verification) { create(:verification, status: 'pending') }
    let!(:approved_verification) { create(:verification, status: 'approved') }
    let!(:rejected_verification) { create(:verification, status: 'rejected') }
    let!(:expired_verification) { create(:verification, status: 'expired') }

    describe '.pending' do
      it 'returns only pending verifications' do
        expect(Verification.pending).to include(pending_verification)
        expect(Verification.pending).not_to include(approved_verification, rejected_verification, expired_verification)
      end
    end

    describe '.approved' do
      it 'returns only approved verifications' do
        expect(Verification.approved).to include(approved_verification)
        expect(Verification.approved).not_to include(pending_verification, rejected_verification, expired_verification)
      end
    end

    describe '.active' do
      it 'returns non-expired verifications' do
        expect(Verification.active).to include(pending_verification, approved_verification, rejected_verification)
        expect(Verification.active).not_to include(expired_verification)
      end
    end

    describe '.recent' do
      let!(:recent_verification) { create(:verification, created_at: 1.day.ago) }
      let!(:old_verification) { create(:verification, created_at: 2.months.ago) }

      it 'returns verifications from last 30 days' do
        expect(Verification.recent).to include(recent_verification)
        expect(Verification.recent).not_to include(old_verification)
      end
    end
  end

  describe 'methods' do
    let(:verification) { create(:verification, status: 'pending') }

    describe '#approve!' do
      let(:admin) { create(:user, role: 'admin') }

      it 'approves the verification' do
        verification.approve!(admin)
        expect(verification.status).to eq('approved')
      end

      it 'sets the verified_by user' do
        verification.approve!(admin)
        expect(verification.verified_by).to eq(admin)
      end

      it 'sets the verified_at timestamp' do
        verification.approve!(admin)
        expect(verification.verified_at).to be_present
      end

      it 'updates user verification status' do
        verification = create(:verification, verification_type: 'identity', status: 'pending')
        expect {
          verification.approve!(admin)
        }.to change { verification.user.reload.identity_verified? }.from(false).to(true)
      end
    end

    describe '#reject!' do
      let(:admin) { create(:user, role: 'admin') }

      it 'rejects the verification with reason' do
        verification.reject!(admin, 'Document unclear')
        expect(verification.status).to eq('rejected')
        expect(verification.rejection_reason).to eq('Document unclear')
      end

      it 'sets the verified_by user' do
        verification.reject!(admin, 'Invalid document')
        expect(verification.verified_by).to eq(admin)
      end

      it 'sets the verified_at timestamp' do
        verification.reject!(admin, 'Invalid document')
        expect(verification.verified_at).to be_present
      end
    end

    describe '#expire!' do
      it 'marks verification as expired' do
        verification.expire!
        expect(verification.status).to eq('expired')
      end

      it 'sets expiry timestamp' do
        verification.expire!
        expect(verification.expired_at).to be_present
      end
    end

    describe '#can_be_reviewed?' do
      it 'returns true for pending verifications' do
        verification = build(:verification, status: 'pending')
        expect(verification.can_be_reviewed?).to be true
      end

      it 'returns true for in_review verifications' do
        verification = build(:verification, status: 'in_review')
        expect(verification.can_be_reviewed?).to be true
      end

      it 'returns false for approved verifications' do
        verification = build(:verification, status: 'approved')
        expect(verification.can_be_reviewed?).to be false
      end

      it 'returns false for rejected verifications' do
        verification = build(:verification, status: 'rejected')
        expect(verification.can_be_reviewed?).to be false
      end
    end

    describe '#requires_document?' do
      it 'returns true for identity verification' do
        verification = build(:verification, verification_type: 'identity')
        expect(verification.requires_document?).to be true
      end

      it 'returns true for income verification' do
        verification = build(:verification, verification_type: 'income')
        expect(verification.requires_document?).to be true
      end

      it 'returns false for email verification' do
        verification = build(:verification, verification_type: 'email')
        expect(verification.requires_document?).to be false
      end

      it 'returns false for phone verification' do
        verification = build(:verification, verification_type: 'phone')
        expect(verification.requires_document?).to be false
      end
    end
  end

  describe 'callbacks' do
    describe '#set_expiry_date' do
      it 'sets expiry date based on verification type' do
        email_verification = create(:verification, verification_type: 'email')
        expect(email_verification.expires_at).to be_within(1.minute).of(7.days.from_now)

        identity_verification = create(:verification, verification_type: 'identity')
        expect(identity_verification.expires_at).to be_within(1.minute).of(1.year.from_now)
      end
    end

    describe '#check_expiry' do
      it 'automatically expires old verifications' do
        verification = create(:verification, expires_at: 1.day.ago)
        verification.check_expiry
        expect(verification.status).to eq('expired')
      end

      it 'does not expire valid verifications' do
        verification = create(:verification, expires_at: 1.day.from_now, status: 'approved')
        verification.check_expiry
        expect(verification.status).to eq('approved')
      end
    end

    describe '#notify_user' do
      it 'sends notification on approval' do
        verification = create(:verification, status: 'pending')
        admin = create(:user, role: 'admin')

        expect {
          verification.approve!(admin)
        }.to have_enqueued_job(VerificationNotificationJob).with(verification, 'approved')
      end

      it 'sends notification on rejection' do
        verification = create(:verification, status: 'pending')
        admin = create(:user, role: 'admin')

        expect {
          verification.reject!(admin, 'Invalid')
        }.to have_enqueued_job(VerificationNotificationJob).with(verification, 'rejected')
      end
    end
  end

  describe 'file attachments' do
    let(:verification) { create(:verification, verification_type: 'identity') }

    it 'can have attached documents' do
      verification.documents.attach(
        io: File.open(Rails.root.join('spec/fixtures/test_document.pdf')),
        filename: 'identity_document.pdf',
        content_type: 'application/pdf'
      )
      expect(verification.documents).to be_attached
    end
  end
end
