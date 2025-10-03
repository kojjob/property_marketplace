require 'rails_helper'

RSpec.describe BlogCategory, type: :model do
  describe 'associations' do
    it { should have_many(:blog_post_categories).dependent(:destroy) }
    it { should have_many(:blog_posts).through(:blog_post_categories) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(100) }
    it { should validate_presence_of(:slug) }
    it { should allow_value('valid-slug').for(:slug) }
    it { should allow_value('valid-slug-123').for(:slug) }
    it { should_not allow_value('Invalid Slug').for(:slug) }
    it { should_not allow_value('invalid_slug!').for(:slug) }
    it { should validate_length_of(:description).is_at_most(500) }

    describe 'slug uniqueness' do
      let!(:existing_category) { create(:blog_category, slug: 'test-slug') }

      it 'validates uniqueness of slug' do
        new_category = build(:blog_category, slug: 'test-slug')
        expect(new_category).not_to be_valid
        expect(new_category.errors[:slug]).to include('has already been taken')
      end
    end
  end

  describe 'callbacks' do
    context 'slug generation' do
      it 'generates slug from name before validation' do
        category = build(:blog_category, name: 'Property Management Tips', slug: nil)
        category.valid?
        expect(category.slug).to eq('property-management-tips')
      end

      it 'does not overwrite existing slug' do
        category = build(:blog_category, name: 'Test Category', slug: 'custom-slug')
        category.valid?
        expect(category.slug).to eq('custom-slug')
      end

      it 'handles duplicate slugs by appending numbers' do
        create(:blog_category, name: 'Test Category', slug: 'test-category')
        category = BlogCategory.create(name: 'Test Category')
        expect(category.slug).to eq('test-category-1')
      end

      it 'handles factory-generated duplicate slugs' do
        # Create a category manually to control the slug
        create(:blog_category, name: 'Manual Category', slug: 'manual-category')
        # Now create another with same name - should get manual-category-1
        category = BlogCategory.create(name: 'Manual Category')
        expect(category.slug).to eq('manual-category-1')
      end
    end
  end

  describe 'scopes' do
    describe '.alphabetical' do
      it 'orders categories by name ascending' do
        category_z = create(:blog_category, name: 'Zebra')
        category_a = create(:blog_category, name: 'Apple')

        expect(BlogCategory.alphabetical).to eq([ category_a, category_z ])
      end
    end

    describe '.with_posts' do
      it 'returns categories that have associated blog posts' do
        category_with_posts = create(:blog_category, :with_posts)
        category_without_posts = create(:blog_category)

        expect(BlogCategory.with_posts).to include(category_with_posts)
        expect(BlogCategory.with_posts).not_to include(category_without_posts)
      end
    end
  end

  describe 'search functionality' do
    it 'searches by name' do
      category = create(:blog_category, name: 'Property Management')
      expect(BlogCategory.search_full_text('Property')).to include(category)
    end

    it 'searches by description' do
      category = create(:blog_category, description: 'Tips for landlords')
      expect(BlogCategory.search_full_text('landlords')).to include(category)
    end
  end

  describe '#to_param' do
    it 'returns the slug' do
      category = create(:blog_category, slug: 'test-category')
      expect(category.to_param).to eq('test-category')
    end
  end

  describe '#post_count' do
    it 'returns count of published blog posts' do
      category = create(:blog_category)
      published_post = create(:blog_post, :published)
      draft_post = create(:blog_post, :draft)
      create(:blog_post_category, blog_post: published_post, blog_category: category)
      create(:blog_post_category, blog_post: draft_post, blog_category: category)

      expect(category.post_count).to eq(1)
    end
  end

  describe 'factory' do
    it 'creates valid blog categories' do
      category = create(:blog_category)
      expect(category).to be_valid
    end

    it 'creates categories with posts using trait' do
      category = create(:blog_category, :with_posts)
      expect(category.blog_posts.count).to eq(3)
    end

    it 'creates property management category' do
      category = create(:blog_category, :property_management)
      expect(category.name).to eq('Property Management')
      expect(category.slug).to eq('property-management')
    end

    it 'creates real estate trends category' do
      category = create(:blog_category, :real_estate_trends)
      expect(category.name).to eq('Real Estate Trends')
      expect(category.slug).to eq('real-estate-trends')
    end
  end
end
