require 'rails_helper'

RSpec.describe Review, type: :model do
  describe 'associations' do
    it { should belong_to(:reviewable) }
    it { should belong_to(:reviewer).class_name('User').with_foreign_key('reviewer_id') }
    it { should belong_to(:booking).optional }
  end

  describe 'validations' do
    subject { build(:review) }

    it { should validate_presence_of(:rating) }
    it { should validate_inclusion_of(:rating).in_range(1..5) }
    it { should validate_presence_of(:review_type) }
    it { should validate_length_of(:title).is_at_most(100) }
    it { should validate_length_of(:content).is_at_least(10).is_at_most(1000) }

    describe 'custom validations' do
      context '#reviewer_cannot_review_own_property' do
        let(:user) { create(:user) }
        let(:property) { create(:property, user: user) }
        let(:listing) { create(:listing, property: property, user: user) }

        it 'prevents users from reviewing their own listings' do
          review = build(:review, reviewable: listing, reviewer: user)
          expect(review).not_to be_valid
          expect(review.errors[:reviewer]).to include("can't review own property")
        end

        it 'allows users to review other listings' do
          other_user = create(:user)
          review = build(:review, reviewable: listing, reviewer: other_user)
          expect(review).to be_valid
        end
      end

      context '#one_review_per_booking' do
        let(:user) { create(:user) }
        let(:listing) { create(:listing) }
        let(:booking) { create(:booking, listing: listing, tenant: user, status: 'completed') }

        it 'allows one review per booking' do
          review = build(:review,
                        reviewable: listing,
                        reviewer: user,
                        booking: booking,
                        review_type: 'tenant_to_property')
          expect(review).to be_valid
        end

        it 'prevents multiple reviews for the same booking and type' do
          create(:review,
                reviewable: listing,
                reviewer: user,
                booking: booking,
                review_type: 'tenant_to_property')

          duplicate_review = build(:review,
                                  reviewable: listing,
                                  reviewer: user,
                                  booking: booking,
                                  review_type: 'tenant_to_property')

          expect(duplicate_review).not_to be_valid
          expect(duplicate_review.errors[:booking]).to include("already has a review of this type")
        end

        it 'allows different review types for the same booking' do
          create(:review,
                reviewable: listing,
                reviewer: user,
                booking: booking,
                review_type: 'tenant_to_property')

          landlord_review = build(:review,
                                 reviewable: user,
                                 reviewer: listing.user,
                                 booking: booking,
                                 review_type: 'landlord_to_tenant')

          expect(landlord_review).to be_valid
        end
      end

      context '#booking_must_be_completed' do
        let(:landlord) { create(:user) }
        let(:tenant) { create(:user) }
        let(:property) { create(:property, user: landlord) }
        let(:listing) { create(:listing, property: property, user: landlord) }
        let(:booking) { create(:booking, listing: listing, tenant: tenant, status: 'pending') }

        it 'requires booking to be completed for property reviews' do
          review = build(:review,
                        booking: booking,
                        reviewable: listing,
                        reviewer: tenant,
                        review_type: 'tenant_to_property')
          expect(review).not_to be_valid
          expect(review.errors[:booking]).to include("must be completed before reviewing")
        end

        it 'allows reviews for completed bookings' do
          booking.update!(status: 'completed')
          review = build(:review,
                        booking: booking,
                        reviewable: listing,
                        reviewer: tenant,
                        review_type: 'tenant_to_property')
          expect(review).to be_valid
        end
      end
    end
  end

  describe 'enums' do
    it { should define_enum_for(:review_type)
          .with_values(
            tenant_to_property: 0,
            landlord_to_tenant: 1,
            tenant_to_landlord: 2,
            property_general: 3
          ) }

    it { should define_enum_for(:status)
          .with_values(
            pending: 0,
            published: 1,
            flagged: 2,
            removed: 3
          ) }
  end

  describe 'scopes' do
    let!(:published_review) { create(:review, status: 'published', rating: 5) }
    let!(:pending_review) { create(:review, status: 'pending', rating: 3) }
    let!(:flagged_review) { create(:review, status: 'flagged', rating: 1) }

    describe '.published' do
      it 'returns only published reviews' do
        expect(Review.published).to include(published_review)
        expect(Review.published).not_to include(pending_review, flagged_review)
      end
    end

    describe '.pending' do
      it 'returns only pending reviews' do
        expect(Review.pending).to include(pending_review)
        expect(Review.pending).not_to include(published_review, flagged_review)
      end
    end

    describe '.high_rating' do
      it 'returns reviews with rating >= 4' do
        expect(Review.high_rating).to include(published_review)
        expect(Review.high_rating).not_to include(pending_review, flagged_review)
      end
    end

    describe '.low_rating' do
      it 'returns reviews with rating <= 2' do
        expect(Review.low_rating).to include(flagged_review)
        expect(Review.low_rating).not_to include(published_review, pending_review)
      end
    end

    describe '.recent' do
      it 'returns reviews from the last 30 days' do
        old_review = create(:review, created_at: 2.months.ago)
        recent_review = create(:review, created_at: 1.week.ago)

        expect(Review.recent).to include(recent_review)
        expect(Review.recent).not_to include(old_review)
      end
    end

    describe '.for_listing' do
      let(:listing) { create(:listing) }
      let!(:listing_review) { create(:review, reviewable: listing) }
      let!(:other_review) { create(:review) }

      it 'returns reviews for a specific listing' do
        expect(Review.for_listing(listing.id)).to include(listing_review)
        expect(Review.for_listing(listing.id)).not_to include(other_review)
      end
    end
  end

  describe 'methods' do
    describe '#helpful_votes_count' do
      let(:review) { create(:review) }

      it 'returns 0 when no helpful votes' do
        expect(review.helpful_votes_count).to eq(0)
      end

      it 'returns count of helpful votes' do
        review.update!(helpful_count: 10)
        expect(review.helpful_votes_count).to eq(10)
      end
    end

    describe '#response_from_owner' do
      let(:review) { create(:review) }

      it 'returns nil when no response exists' do
        expect(review.response_from_owner).to be_nil
      end

      it 'returns the response content when exists' do
        review.update!(response: "Thank you for your feedback")
        expect(review.response_from_owner).to eq("Thank you for your feedback")
      end
    end

    describe '#can_be_edited?' do
      let(:review) { create(:review, created_at: 1.hour.ago) }

      it 'returns true within 48 hours of creation' do
        expect(review.can_be_edited?).to be true
      end

      it 'returns false after 48 hours' do
        review.update!(created_at: 3.days.ago)
        expect(review.can_be_edited?).to be false
      end

      it 'returns false if review has a response' do
        review.update!(response: "Thanks for the review")
        expect(review.can_be_edited?).to be false
      end
    end

    describe '#average_rating_for' do
      let(:listing) { create(:listing) }

      it 'calculates average rating for a reviewable item' do
        create(:review, reviewable: listing, rating: 4, status: 'published')
        create(:review, reviewable: listing, rating: 5, status: 'published')
        create(:review, reviewable: listing, rating: 3, status: 'published')

        expect(Review.average_rating_for(listing)).to eq(4.0)
      end

      it 'returns 0 when no published reviews exist' do
        create(:review, reviewable: listing, rating: 5, status: 'pending')

        expect(Review.average_rating_for(listing)).to eq(0)
      end
    end
  end

  describe 'callbacks' do
    describe '#set_default_status' do
      it 'sets status to pending by default' do
        review = Review.new(
          reviewable: create(:listing),
          reviewer: create(:user),
          rating: 4,
          review_type: 'property_general'
        )
        review.save!
        expect(review.status).to eq('pending')
      end
    end

    describe '#update_reviewable_rating' do
      let(:listing) { create(:listing) }

      it 'updates the reviewable average rating after save' do
        create(:review, reviewable: listing, rating: 5, status: 'published')
        create(:review, reviewable: listing, rating: 3, status: 'published')

        # We'll implement this functionality in the model
        listing.reload
        expect(listing.average_rating).to be_present
      end
    end
  end
end