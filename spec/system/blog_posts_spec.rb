require 'rails_helper'

RSpec.describe 'Blog Posts', type: :system do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let!(:published_post) { create(:blog_post, :published, user: user, title: 'Published Blog Post', content: 'This is a published blog post content.') }
  let!(:draft_post) { create(:blog_post, user: user, title: 'Draft Blog Post') }
  let!(:category) { create(:blog_category, name: 'Technology', slug: 'technology') }

  before do
    published_post.categories << category
  end

  describe 'Viewing blog posts' do
    it 'displays published blog posts on index page' do
      visit blog_posts_path

      expect(page).to have_content('Published Blog Post')
      expect(page).to have_content('This is a published blog post content.')
      expect(page).not_to have_content('Draft Blog Post')
    end

    it 'displays blog post show page' do
      visit blog_post_path(published_post.slug)

      expect(page).to have_content('Published Blog Post')
      expect(page).to have_content('This is a published blog post content.')
      expect(page).to have_content('Technology') # category
    end

    it 'filters posts by category' do
      visit blog_posts_path
      click_link 'Technology'

      expect(page).to have_content('Published Blog Post')
      expect(current_url).to include('category=technology')
    end

    it 'searches posts by query' do
      visit blog_posts_path
      fill_in 'query', with: 'Published'
      click_button 'Search'

      expect(page).to have_content('Published Blog Post')
      expect(current_url).to include('query=Published')
    end
  end

  describe 'Creating blog posts' do
    context 'when user is signed in' do
      before do
        sign_in user
        visit new_blog_post_path
      end

      it 'allows creating a new blog post' do
        fill_in 'Title', with: 'New Blog Post'
        fill_in 'blog_post_content', with: 'This is the content of the new blog post.'
        fill_in 'Excerpt', with: 'This is an excerpt'
        check 'Published'
        select 'Technology', from: 'blog_post_category_ids'

        click_button 'Create Blog post'

        expect(page).to have_content('Blog post was successfully created.')
        expect(page).to have_content('New Blog Post')
        expect(page).to have_content('This is the content of the new blog post.')
      end

      it 'shows validation errors for invalid data' do
        click_button 'Create Blog post'

        expect(page).to have_content("Title can't be blank")
        expect(page).to have_content("Content can't be blank")
      end
    end

    context 'when user is not signed in' do
      it 'redirects to sign in page' do
        visit new_blog_post_path

        expect(page).to have_content('You need to sign in')
      end
    end
  end

  describe 'Editing blog posts' do
    context 'when user owns the post' do
      before do
        sign_in user
        visit edit_blog_post_path(published_post.slug)
      end

      it 'allows editing the blog post' do
        fill_in 'Title', with: 'Updated Blog Post Title'
        click_button 'Update Blog post'

        expect(page).to have_content('Blog post was successfully updated.')
        expect(page).to have_content('Updated Blog Post Title')
      end
    end

    context 'when user is admin' do
      before do
        sign_in admin
        visit edit_blog_post_path(published_post.slug)
      end

      it 'allows editing any blog post' do
        fill_in 'Title', with: 'Admin Updated Title'
        click_button 'Update Blog post'

        expect(page).to have_content('Blog post was successfully updated.')
        expect(page).to have_content('Admin Updated Title')
      end
    end

    context 'when user does not own the post' do
      let(:other_user) { create(:user) }

      before do
        sign_in other_user
        visit edit_blog_post_path(published_post.slug)
      end

      it 'shows authorization error' do
        expect(page).to have_content('You are not authorized')
      end
    end
  end

  describe 'Deleting blog posts' do
    context 'when user owns the post' do
      before do
        sign_in user
        visit blog_post_path(published_post.slug)
      end

      it 'allows deleting the blog post' do
        accept_confirm do
          click_link 'Delete'
        end

        expect(page).to have_content('Blog post was successfully destroyed.')
        expect(page).not_to have_content('Published Blog Post')
      end
    end
  end

  describe 'Comments' do
    context 'when user is signed in' do
      before do
        sign_in user
        visit blog_post_path(published_post.slug)
      end

      it 'allows adding comments' do
        fill_in 'comment_content', with: 'This is a great post!'
        click_button 'Post Comment'

        expect(page).to have_content('Comment was successfully posted.')
        expect(page).to have_content('This is a great post!')
      end

      it 'allows replying to comments' do
        # First create a comment
        fill_in 'comment_content', with: 'Original comment'
        click_button 'Post Comment'

        # Then reply to it
        within('.comment') do
          click_link 'Reply'
          fill_in 'comment_content', with: 'This is a reply'
          click_button 'Post Comment'
        end

        expect(page).to have_content('This is a reply')
      end
    end

    context 'when user is not signed in' do
      before do
        visit blog_post_path(published_post.slug)
      end

      it 'allows guest comments' do
        fill_in 'comment_author_name', with: 'Guest User'
        fill_in 'comment_author_email', with: 'guest@example.com'
        fill_in 'comment_content', with: 'Great post from a guest!'
        click_button 'Post Comment'

        expect(page).to have_content('Comment was successfully posted.')
        expect(page).to have_content('Great post from a guest!')
      end
    end

    context 'when user is admin' do
      let!(:pending_comment) { create(:comment, blog_post: published_post, content: 'Pending comment') }

      before do
        sign_in admin
        visit blog_post_path(published_post.slug)
      end

      it 'allows approving comments' do
        within('.comment') do
          click_button 'Approve'
        end

        expect(page).to have_content('Comment was approved.')
      end

      it 'allows rejecting comments' do
        within('.comment') do
          click_button 'Reject'
        end

        expect(page).to have_content('Comment was rejected.')
      end
    end
  end

  describe 'Rich media content' do
    let!(:post_with_media) { create(:blog_post, :published, user: user, title: 'Media Post') }

    before do
      # Attach some test files to the post
      post_with_media.media_files.attach(
        io: File.open(Rails.root.join('spec/fixtures/files/test_image.jpg')),
        filename: 'test_image.jpg',
        content_type: 'image/jpeg'
      )
      post_with_media.save!
    end

    it 'displays attached media files' do
      visit blog_post_path(post_with_media.slug)

      expect(page).to have_content('Media Post')
      # Check for media file display (this would depend on your view implementation)
    end
  end
end
