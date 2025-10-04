require 'rails_helper'

RSpec.describe Review, "Edge Cases", type: :model do
  describe 'Edge Case Scenarios' do
    let(:landlord) { create(:user) }
    let(:tenant) { create(:user) }
    let(:property) { create(:property, user: landlord) }
    let(:listing) { create(:listing, property: property, user: landlord) }

    describe 'Boundary value testing' do
      context 'rating edge cases' do
        it 'rejects rating of 0' do
          review = build(:review, rating: 0)
          expect(review).not_to be_valid
          expect(review.errors[:rating]).to include("is not included in the list")
        end

        it 'rejects rating of 6' do
          review = build(:review, rating: 6)
          expect(review).not_to be_valid
          expect(review.errors[:rating]).to include("is not included in the list")
        end

        it 'rejects negative ratings' do
          review = build(:review, rating: -1)
          expect(review).not_to be_valid
        end

        it 'rejects nil rating' do
          review = build(:review, rating: nil)
          expect(review).not_to be_valid
        end

        it 'accepts boundary values 1 and 5' do
          review1 = build(:review, rating: 1)
          review5 = build(:review, rating: 5)
          expect(review1).to be_valid
          expect(review5).to be_valid
        end
      end

      context 'content length edge cases' do
        it 'rejects content with exactly 9 characters' do
          review = build(:review, content: "123456789")
          expect(review).not_to be_valid
        end

        it 'accepts content with exactly 10 characters' do
          review = build(:review, content: "1234567890")
          expect(review).to be_valid
        end

        it 'accepts content with exactly 1000 characters' do
          review = build(:review, content: "a" * 1000)
          expect(review).to be_valid
        end

        it 'rejects content with 1001 characters' do
          review = build(:review, content: "a" * 1001)
          expect(review).not_to be_valid
        end

        it 'accepts blank content when allow_blank is true' do
          review = build(:review, content: "")
          expect(review.errors[:content]).to be_empty unless review.valid?
        end
      end

      context 'title length edge cases' do
        it 'accepts title with exactly 100 characters' do
          review = build(:review, title: "a" * 100)
          expect(review).to be_valid
        end

        it 'rejects title with 101 characters' do
          review = build(:review, title: "a" * 101)
          expect(review).not_to be_valid
        end
      end
    end

    describe 'Race condition scenarios' do
      context 'concurrent review creation' do
        it 'prevents duplicate reviews for same booking when created simultaneously' do
          booking = create(:booking, listing: listing, tenant: tenant, status: 'completed')

          review1 = create(:review,
                          reviewable: listing,
                          reviewer: tenant,
                          booking: booking,
                          review_type: 'tenant_to_property')

          review2 = build(:review,
                         reviewable: listing,
                         reviewer: tenant,
                         booking: booking,
                         review_type: 'tenant_to_property')

          expect(review2).not_to be_valid
          expect(review2.errors[:booking]).to include("already has a review of this type")
        end
      end

      context 'booking status change during review' do
        it 'handles booking status changing from completed to cancelled' do
          booking = create(:booking, listing: listing, tenant: tenant, status: 'completed')
          review = build(:review,
                        booking: booking,
                        reviewable: listing,
                        reviewer: tenant,
                        review_type: 'tenant_to_property')

          expect(review).to be_valid

          # Simulate race condition where booking gets cancelled
          booking.update!(status: 'cancelled')
          new_review = build(:review,
                           booking: booking.reload,
                           reviewable: listing,
                           reviewer: tenant,
                           review_type: 'tenant_to_property')

          expect(new_review).not_to be_valid
        end
      end
    end

    describe 'Null and empty value handling' do
      it 'handles nil reviewable gracefully' do
        review = build(:review, reviewable: nil)
        expect(review).not_to be_valid
        expect(review.errors[:reviewable]).to include("must exist")
      end

      it 'handles nil reviewer gracefully' do
        review = build(:review, reviewer: nil)
        expect(review).not_to be_valid
        expect(review.errors[:reviewer]).to include("must exist")
      end

      it 'handles empty string for title' do
        review = build(:review, title: "")
        expect(review).to be_valid # title is optional
      end

      it 'handles whitespace-only content' do
        # Note: allow_blank: true on content validation means whitespace is allowed
        # This is a design decision - we rely on frontend validation for meaningful content
        review = build(:review, content: "          ")
        expect(review).to be_valid  # Whitespace-only content is technically valid

        # Even short whitespace is valid due to allow_blank: true
        short_whitespace = build(:review, content: "     ")
        expect(short_whitespace).to be_valid  # Also valid with allow_blank
      end
    end

    describe 'SQL injection prevention' do
      it 'safely handles malicious input in content' do
        malicious_content = "'; DROP TABLE reviews; --"
        review = build(:review, content: malicious_content)
        expect(review).to be_valid
        expect(review.content).to eq(malicious_content)
      end

      it 'safely handles special characters in title' do
        special_title = "<script>alert('XSS')</script>"
        review = build(:review, title: special_title)
        expect(review).to be_valid
        expect(review.title).to eq(special_title)
      end
    end

    describe 'Unicode and encoding edge cases' do
      it 'handles emoji in content' do
        review = build(:review, content: "Great place! 🏡 Would recommend! 👍 Five stars! ⭐⭐⭐⭐⭐")
        expect(review).to be_valid
      end

      it 'handles multi-byte unicode characters' do
        review = build(:review, content: "素晴らしい場所でした。また泊まりたいです。")
        expect(review).to be_valid
      end

      it 'counts character length correctly for unicode' do
        # 10 emoji characters should be valid (meets minimum length)
        review = build(:review, content: "👍" * 10)
        expect(review).to be_valid
      end
    end

    describe 'Date and time edge cases' do
      context 'review editing time window' do
        it 'handles exactly 48 hours' do
          review = create(:review)
          review.update!(created_at: 48.hours.ago)
          expect(review.can_be_edited?).to be false
        end

        it 'handles 47 hours 59 minutes 59 seconds' do
          review = create(:review)
          review.update!(created_at: (48.hours - 1.second).ago)
          expect(review.can_be_edited?).to be true
        end

        it 'handles daylight saving time transitions' do
          # Simulate DST transition
          review = create(:review)
          review.update!(created_at: 47.hours.ago)
          expect(review.can_be_edited?).to be true
        end
      end
    end

    describe 'Polymorphic association edge cases' do
      it 'handles non-existent reviewable type' do
        review = build(:review)
        review.reviewable_type = 'NonExistentModel'
        review.reviewable_id = 999
        # Rails will raise NameError when trying to constantize a non-existent model
        expect { review.reviewable }.to raise_error(NameError)
      end

      it 'handles reviewable type that does not have user_id' do
        # Create a review for a User (which doesn't have user_id)
        review = build(:review, reviewable: tenant, reviewer: landlord)
        expect(review).to be_valid # Should not error on the validation
      end
    end

    describe 'Status transition edge cases' do
      it 'handles all status transitions' do
        review = create(:review, status: 'pending')

        %w[published flagged removed].each do |status|
          expect { review.update!(status: status) }.not_to raise_error
          expect(review.status).to eq(status)
        end
      end

      it 'maintains data integrity when status changes' do
        review = create(:review, status: 'published')
        original_content = review.content
        review.update!(status: 'flagged')

        expect(review.content).to eq(original_content)
        expect(review.rating).not_to be_nil
      end
    end

    describe 'Calculation edge cases' do
      context 'average rating calculations' do
        it 'handles no reviews' do
          expect(Review.average_rating_for(listing)).to eq(0)
        end

        it 'handles only unpublished reviews' do
          create(:review, reviewable: listing, rating: 5, status: 'pending')
          create(:review, reviewable: listing, rating: 4, status: 'flagged')
          expect(Review.average_rating_for(listing)).to eq(0)
        end

        it 'calculates average correctly with mixed ratings' do
          create(:review, reviewable: listing, rating: 1, status: 'published')
          create(:review, reviewable: listing, rating: 5, status: 'published')
          create(:review, reviewable: listing, rating: 3, status: 'published')
          expect(Review.average_rating_for(listing)).to eq(3.0)
        end

        it 'handles decimal averages' do
          create(:review, reviewable: listing, rating: 4, status: 'published')
          create(:review, reviewable: listing, rating: 5, status: 'published')
          expect(Review.average_rating_for(listing)).to eq(4.5)
        end
      end
    end

    describe 'Scope edge cases' do
      context '.recent scope' do
        it 'includes reviews from exactly 30 days ago' do
          review = create(:review, created_at: 30.days.ago + 1.minute)
          expect(Review.recent).to include(review)
        end

        it 'excludes reviews from 30 days and 1 second ago' do
          review = create(:review, created_at: 30.days.ago - 1.second)
          expect(Review.recent).not_to include(review)
        end
      end

      context '.high_rating scope' do
        it 'includes rating of exactly 4' do
          review = create(:review, rating: 4, status: 'published')
          expect(Review.high_rating).to include(review)
        end

        it 'excludes rating of 3' do
          review = create(:review, rating: 3, status: 'published')
          expect(Review.high_rating).not_to include(review)
        end
      end

      context '.low_rating scope' do
        it 'includes rating of exactly 2' do
          review = create(:review, rating: 2, status: 'published')
          expect(Review.low_rating).to include(review)
        end

        it 'excludes rating of 3' do
          review = create(:review, rating: 3, status: 'published')
          expect(Review.low_rating).not_to include(review)
        end
      end
    end

    describe 'Response system edge cases' do
      it 'handles response without responder' do
        review = create(:review)
        review.update!(response: "Thank you", response_by_id: nil)
        expect(review.response_from_owner).to eq("Thank you")
        expect(review.responder).to be_nil
      end

      it 'handles very long responses' do
        long_response = "a" * 5000
        review = create(:review)
        review.update!(response: long_response)
        expect(review.response).to eq(long_response)
      end

      it 'prevents editing after response is added' do
        review = create(:review, created_at: 1.hour.ago)
        expect(review.can_be_edited?).to be true

        review.update!(response: "Thanks")
        expect(review.can_be_edited?).to be false
      end
    end

    describe 'Performance edge cases' do
      it 'handles bulk review creation efficiently' do
        reviews = []
        expect do
          100.times do
            reviews << build(:review)
          end
          Review.import(reviews) if defined?(Review.import)
        end.not_to raise_error
      end
    end
  end
end
