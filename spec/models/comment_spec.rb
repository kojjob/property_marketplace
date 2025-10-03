require 'rails_helper'

RSpec.describe Comment, type: :model do
  let(:blog_post) { create(:blog_post) }
  let(:user) { create(:user) }
  let(:comment) { create(:comment, blog_post: blog_post) }

  describe 'associations' do
    it { should belong_to(:blog_post) }
    it { should belong_to(:parent).class_name('Comment').optional }
    it { should belong_to(:user).optional }
    it { should have_many(:replies).class_name('Comment').dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content) }
    it { should validate_length_of(:content).is_at_most(2000) }
    it { should validate_inclusion_of(:status).in_array(%w[pending approved rejected]) }

    context 'for guest comments' do
      subject { build(:comment, :guest, blog_post: blog_post) }

      it { should validate_presence_of(:author_name) }
      it { should validate_presence_of(:author_email) }
      it { should allow_value('user@example.com').for(:author_email) }
      it { should_not allow_value('invalid-email').for(:author_email) }
    end

    context 'for user comments' do
      subject { build(:comment, :from_user, blog_post: blog_post, user: user) }

      it { should_not validate_presence_of(:author_name) }
      it { should_not validate_presence_of(:author_email) }
    end
  end

  describe 'callbacks' do
    describe 'default status' do
      it 'sets status to pending by default' do
        comment = create(:comment, blog_post: blog_post, status: nil)
        expect(comment.status).to eq('pending')
      end
    end
  end

  describe 'scopes' do
    let!(:approved_comment) { create(:comment, :approved, blog_post: blog_post) }
    let!(:pending_comment) { create(:comment, :pending, blog_post: blog_post) }
    let!(:rejected_comment) { create(:comment, :rejected, blog_post: blog_post) }

    describe '.approved' do
      it 'returns only approved comments' do
        expect(Comment.approved).to include(approved_comment)
        expect(Comment.approved).not_to include(pending_comment, rejected_comment)
      end
    end

    describe '.pending' do
      it 'returns only pending comments' do
        expect(Comment.pending).to include(pending_comment)
        expect(Comment.pending).not_to include(approved_comment, rejected_comment)
      end
    end

    describe '.rejected' do
      it 'returns only rejected comments' do
        expect(Comment.rejected).to include(rejected_comment)
        expect(Comment.rejected).not_to include(approved_comment, pending_comment)
      end
    end

    describe '.root_comments' do
      let!(:reply) { create(:comment, :reply, blog_post: blog_post, parent: approved_comment) }

      it 'returns only root comments' do
        expect(Comment.root_comments).to include(approved_comment, pending_comment, rejected_comment)
        expect(Comment.root_comments).not_to include(reply)
      end
    end
  end

  describe 'methods' do
    describe '#user?' do
      it 'returns true for user comments' do
        user_comment = create(:comment, :from_user, blog_post: blog_post, user: user)
        expect(user_comment.user?).to be true
      end

      it 'returns false for guest comments' do
        guest_comment = create(:comment, :guest, blog_post: blog_post)
        expect(guest_comment.user?).to be false
      end
    end

    describe '#guest?' do
      it 'returns true for guest comments' do
        guest_comment = create(:comment, :guest, blog_post: blog_post)
        expect(guest_comment.guest?).to be true
      end

      it 'returns false for user comments' do
        user_comment = create(:comment, :from_user, blog_post: blog_post, user: user)
        expect(user_comment.guest?).to be false
      end
    end

    describe '#approved?' do
      it 'returns true for approved comments' do
        expect(create(:comment, :approved, blog_post: blog_post).approved?).to be true
      end

      it 'returns false for non-approved comments' do
        expect(create(:comment, :pending, blog_post: blog_post).approved?).to be false
      end
    end

    describe '#approve!' do
      it 'sets status to approved and approved_at timestamp' do
        comment = create(:comment, :pending, blog_post: blog_post)
        comment.approve!
        expect(comment.status).to eq('approved')
        expect(comment.approved_at).to be_present
      end
    end

    describe '#reject!' do
      it 'sets status to rejected' do
        comment = create(:comment, :pending, blog_post: blog_post)
        comment.reject!
        expect(comment.status).to eq('rejected')
      end
    end

    describe '#author_display_name' do
      it 'returns user name for user comments' do
        user_comment = create(:comment, :from_user, blog_post: blog_post, user: user)
        expect(user_comment.author_display_name).to eq(user.profile.first_name)
      end

      it 'returns author_name for guest comments' do
        guest_comment = create(:comment, :guest, blog_post: blog_post, author_name: 'John Doe')
        expect(guest_comment.author_display_name).to eq('John Doe')
      end
    end

    describe '#author_email_address' do
      it 'returns user email for user comments' do
        user_comment = create(:comment, :from_user, blog_post: blog_post, user: user)
        expect(user_comment.author_email_address).to eq(user.email)
      end

      it 'returns author_email for guest comments' do
        guest_comment = create(:comment, :guest, blog_post: blog_post, author_email: 'john@example.com')
        expect(guest_comment.author_email_address).to eq('john@example.com')
      end
    end

    describe '#root_comment?' do
      it 'returns true for root comments' do
        expect(comment.root_comment?).to be true
      end

      it 'returns false for replies' do
        reply = create(:comment, :reply, blog_post: blog_post, parent: comment)
        expect(reply.root_comment?).to be false
      end
    end

    describe '#reply?' do
      it 'returns false for root comments' do
        expect(comment.reply?).to be false
      end

      it 'returns true for replies' do
        reply = create(:comment, :reply, blog_post: blog_post, parent: comment)
        expect(reply.reply?).to be true
      end
    end
  end
end
