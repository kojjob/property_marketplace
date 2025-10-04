require 'rails_helper'

RSpec.describe BlogPost, type: :model do
  let(:user) { create(:user) }
  let(:blog_post) { create(:blog_post, user: user) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:comments).dependent(:destroy) }
    it { should have_many(:blog_post_categories).dependent(:destroy) }
    it { should have_many(:categories).through(:blog_post_categories) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_most(200) }
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:slug) }

    describe 'slug uniqueness' do
      let!(:existing_post) { create(:blog_post, slug: 'test-slug') }

      it 'validates uniqueness of slug' do
        new_post = build(:blog_post, slug: 'test-slug')
        expect(new_post).not_to be_valid
        expect(new_post.errors[:slug]).to include('has already been taken')
      end
    end
    it { should allow_value('valid-slug-123').for(:slug) }
    it { should_not allow_value('Invalid Slug!').for(:slug) }
    it { should validate_length_of(:excerpt).is_at_most(500) }
    it { should validate_length_of(:meta_title).is_at_most(60) }
    it { should validate_length_of(:meta_description).is_at_most(160) }
    it { should validate_length_of(:meta_keywords).is_at_most(200) }
  end

  describe 'scopes' do
    let!(:published_post) { create(:blog_post, :published, user: user, published_at: 1.day.ago) }
    let!(:draft_post) { create(:blog_post, :draft, user: user) }
    let!(:future_post) { create(:blog_post, :published, user: user, published_at: 1.day.from_now) }

    describe '.published' do
      it 'returns only published posts with past published_at' do
        expect(BlogPost.published).to include(published_post)
        expect(BlogPost.published).not_to include(draft_post)
        expect(BlogPost.published).not_to include(future_post)
      end
    end

    describe '.draft' do
      it 'returns only draft posts' do
        expect(BlogPost.draft).to include(draft_post)
        expect(BlogPost.draft).not_to include(published_post)
      end
    end

    describe '.recent' do
      it 'orders by published_at descending' do
        recent_posts = BlogPost.recent
        # Should include all posts ordered by published_at desc
        # future_post should be first (most recent published_at)
        # published_post should be second
        # draft_post should be last (NULL published_at sorts last)
        expect(recent_posts[0]).to eq(future_post)
        expect(recent_posts[1]).to eq(published_post)
        expect(recent_posts[2]).to eq(draft_post)
      end
    end
  end

  describe 'callbacks' do
    describe 'slug generation' do
      it 'generates slug from title' do
        post = create(:blog_post, title: 'Hello World!', user: user)
        expect(post.slug).to eq('hello-world')
      end

      it 'handles duplicate slugs' do
        create(:blog_post, title: 'Test Post', user: user)
        post2 = create(:blog_post, title: 'Test Post', user: user)
        expect(post2.slug).to eq('test-post-1')
      end

      it 'does not regenerate slug if already set' do
        post = create(:blog_post, title: 'Original Title', slug: 'custom-slug', user: user)
        post.update(title: 'New Title')
        expect(post.slug).to eq('custom-slug')
      end
    end

    describe 'published_at setting' do
      it 'sets published_at when publishing' do
        post = create(:blog_post, :draft, user: user)
        post.update(published: true)
        expect(post.published_at).to be_present
      end

      it 'does not change published_at if already set' do
        original_time = 1.day.ago
        post = create(:blog_post, :published, published_at: original_time, user: user)
        post.update(title: 'New Title')
        expect(post.published_at).to eq(original_time)
      end
    end
  end

  describe 'methods' do
    describe '#to_param' do
      it 'returns the slug' do
        expect(blog_post.to_param).to eq(blog_post.slug)
      end
    end

    describe '#published?' do
      it 'returns true for published posts' do
        published_post = create(:blog_post, :published, user: user)
        expect(published_post.published?).to be true
      end

      it 'returns false for draft posts' do
        draft_post = create(:blog_post, :draft, user: user)
        expect(draft_post.published?).to be false
      end
    end

    describe '#reading_time' do
      it 'calculates reading time based on word count' do
        post = create(:blog_post, content: 'word ' * 400, user: user) # 400 words
        expect(post.reading_time).to eq(2) # 400 words / 200 wpm = 2 minutes
      end
    end

    describe '#meta_title_or_title' do
      it 'returns meta_title if present' do
        post = create(:blog_post, title: 'Default Title', meta_title: 'Custom Meta Title', user: user)
        expect(post.meta_title_or_title).to eq('Custom Meta Title')
      end

      it 'returns title if meta_title is blank' do
        post = create(:blog_post, title: 'Default Title', meta_title: '', user: user)
        expect(post.meta_title_or_title).to eq('Default Title')
      end
    end

    describe '#meta_description_or_excerpt' do
      it 'returns meta_description if present' do
        post = create(:blog_post, meta_description: 'Custom description', user: user)
        expect(post.meta_description_or_excerpt).to eq('Custom description')
      end

      it 'returns excerpt if meta_description is blank' do
        post = create(:blog_post, excerpt: 'Excerpt text', meta_description: '', user: user)
        expect(post.meta_description_or_excerpt).to eq('Excerpt text')
      end

      it 'returns truncated content if both are blank' do
        long_content = 'word ' * 100
        post = create(:blog_post, content: long_content, excerpt: '', meta_description: '', user: user)
        expect(post.meta_description_or_excerpt.length).to be <= 160
      end
    end
  end

  describe 'search' do
    it 'responds to search_full_text' do
      expect(BlogPost).to respond_to(:search_full_text)
    end
  end
end
