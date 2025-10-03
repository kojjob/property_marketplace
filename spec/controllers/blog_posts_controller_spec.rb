require 'rails_helper'

RSpec.describe BlogPostsController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let(:blog_post) { create(:blog_post, user: user) }
  let(:published_post) { create(:blog_post, :published, user: user) }
  let(:category) { create(:blog_category) }

  describe 'GET #index' do
    let!(:published_posts) { create_list(:blog_post, 3, :published, user: user) }
    let!(:draft_post) { create(:blog_post, user: user) }

    it 'assigns published blog posts to @blog_posts' do
      get :index
      expect(assigns(:blog_posts)).to match_array(published_posts)
    end

    it 'assigns categories with posts to @categories' do
      published_posts.first.categories << category
      get :index
      expect(assigns(:categories)).to include(category)
    end

    context 'with category filter' do
      before { published_posts.first.categories << category }

      it 'filters posts by category' do
        get :index, params: { category: category.slug }
        expect(assigns(:blog_posts)).to eq([ published_posts.first ])
      end
    end

    context 'with search query' do
      let!(:matching_post) { create(:blog_post, :published, title: 'Unique Title', user: user) }

      it 'searches posts by query' do
        get :index, params: { query: 'Unique' }
        expect(assigns(:blog_posts)).to include(matching_post)
      end
    end
  end

  describe 'GET #show' do
    let!(:related_post) { create(:blog_post, :published, user: user) }
    let!(:published_post) { create(:blog_post, :published, user: user) }

    before do
      published_post.categories << category
      related_post.categories << category
    end

    it 'assigns the requested blog post to @blog_post' do
      get :show, params: { slug: published_post.slug }
      expect(assigns(:blog_post)).to eq(published_post)
    end

    it 'assigns related posts' do
      get :show, params: { slug: published_post.slug }
      expect(assigns(:related_posts)).to include(related_post)
    end

    it 'assigns a new comment to @comment' do
      get :show, params: { slug: published_post.slug }
      expect(assigns(:comment)).to be_a_new(Comment)
    end

    context 'with numeric id as string' do
      it 'finds post by id' do
        get :show, params: { slug: published_post.id.to_s }
        expect(assigns(:blog_post)).to eq(published_post)
      end
    end
  end

  describe 'GET #new' do
    context 'when user is authenticated' do
      before { sign_in user }

      it 'assigns a new blog post to @blog_post' do
        get :new
        expect(assigns(:blog_post)).to be_a_new(BlogPost)
        expect(assigns(:blog_post).user).to eq(user)
      end

      it 'assigns categories to @categories' do
        get :new
        expect(assigns(:categories)).to eq(BlogCategory.alphabetical)
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST #create' do
    context 'when user is authenticated' do
      before { sign_in user }

      context 'with valid params' do
        let(:valid_params) do
          {
            blog_post: {
              title: 'Test Post',
              content: 'Test content',
              excerpt: 'Test excerpt',
              published: true,
              category_ids: [ category.id ]
            }
          }
        end

        it 'creates a new blog post' do
          expect {
            post :create, params: valid_params
          }.to change(BlogPost, :count).by(1)
        end

        it 'assigns the blog post to the current user' do
          post :create, params: valid_params
          expect(BlogPost.last.user).to eq(user)
        end

        it 'redirects to the created blog post' do
          post :create, params: valid_params
          expect(response).to redirect_to(BlogPost.last)
        end

        it 'sets the flash notice' do
          post :create, params: valid_params
          expect(flash[:notice]).to eq('Blog post was successfully created.')
        end

        context 'with featured image' do
          let(:file) { fixture_file_upload('test_image.jpg', 'image/jpeg') }
          let(:params_with_image) { valid_params.merge(blog_post: valid_params[:blog_post].merge(featured_image: file)) }

          it 'attaches the featured image' do
            expect {
              post :create, params: params_with_image
            }.to change(ActiveStorage::Attachment, :count).by(1)
          end
        end

        context 'with media files' do
          let(:files) { [ fixture_file_upload('test_image.jpg', 'image/jpeg') ] }
          let(:params_with_files) { valid_params.merge(blog_post: valid_params[:blog_post].merge(media_files: files)) }

          it 'attaches the media files' do
            expect {
              post :create, params: params_with_files
            }.to change(ActiveStorage::Attachment, :count).by(1)
          end
        end
      end

      context 'with invalid params' do
        let(:invalid_params) { { blog_post: { title: '' } } }

        it 'does not create a blog post' do
          expect {
            post :create, params: invalid_params
          }.not_to change(BlogPost, :count)
        end

        it 'renders the new template' do
          post :create, params: invalid_params
          expect(response).to render_template(:new)
        end

        it 'returns unprocessable entity status' do
          post :create, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        post :create, params: { blog_post: { title: 'Test' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET #edit' do
    context 'when user is authenticated' do
      context 'as the post owner' do
        before { sign_in user }

        it 'assigns the requested blog post to @blog_post' do
          get :edit, params: { slug: blog_post.slug }
          expect(assigns(:blog_post)).to eq(blog_post)
        end

        it 'assigns categories to @categories' do
          get :edit, params: { slug: blog_post.slug }
          expect(assigns(:categories)).to eq(BlogCategory.alphabetical)
        end
      end

      context 'as an admin' do
        before { sign_in admin }

        it 'allows editing other users posts' do
          get :edit, params: { slug: blog_post.slug }
          expect(assigns(:blog_post)).to eq(blog_post)
        end
      end

      context 'as another user' do
        let(:other_user) { create(:user) }
        before { sign_in other_user }

        it 'redirects with alert' do
          get :edit, params: { slug: blog_post.slug }
          expect(response).to redirect_to(blog_posts_path)
          expect(flash[:alert]).to eq('You are not authorized to perform this action.')
        end
      end
    end

    context 'when user is not authenticated' do
        it 'redirects to sign in' do
          get :edit, params: { slug: blog_post.slug }
          expect(response).to redirect_to(new_user_session_path)
        end
    end
  end

  describe 'PATCH #update' do
    context 'when user is authenticated' do
      context 'as the post owner' do
        before { sign_in user }

        context 'with valid params' do
        let(:update_params) do
          {
            slug: blog_post.slug,
            blog_post: { title: 'Updated Title' }
          }
        end

          it 'updates the blog post' do
            expect {
              patch :update, params: update_params
            }.to change { blog_post.reload.title }.to('Updated Title')
          end

          it 'redirects to the blog post' do
            patch :update, params: update_params
            expect(response).to redirect_to(blog_post)
          end

          it 'sets the flash notice' do
            patch :update, params: update_params
            expect(flash[:notice]).to eq('Blog post was successfully updated.')
          end
        end

        context 'with invalid params' do
        let(:invalid_params) do
          {
            slug: blog_post.slug,
            blog_post: { title: '' }
          }
        end

          it 'does not update the blog post' do
            expect {
              patch :update, params: invalid_params
            }.not_to change { blog_post.reload.title }
          end

          it 'renders the edit template' do
            patch :update, params: invalid_params
            expect(response).to render_template(:edit)
          end
        end
      end

      context 'as an admin' do
        before { sign_in admin }

        it 'allows updating other users posts' do
          patch :update, params: { slug: blog_post.slug, blog_post: { title: 'Admin Updated' } }
          expect(blog_post.reload.title).to eq('Admin Updated')
        end
      end

      context 'as another user' do
        let(:other_user) { create(:user) }
        before { sign_in other_user }

        it 'redirects with alert' do
          patch :update, params: { slug: blog_post.slug, blog_post: { title: 'Hacked' } }
          expect(response).to redirect_to(blog_posts_path)
          expect(flash[:alert]).to eq('You are not authorized to perform this action.')
        end
      end
    end

    context 'when user is not authenticated' do
        it 'redirects to sign in' do
          patch :update, params: { slug: blog_post.slug, blog_post: { title: 'Test' } }
          expect(response).to redirect_to(new_user_session_path)
        end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user is authenticated' do
      context 'as the post owner' do
        before { sign_in user }
        let!(:post_to_destroy) { create(:blog_post, user: user) }

        it 'destroys the blog post' do
          expect {
            delete :destroy, params: { slug: post_to_destroy.slug }
          }.to change(BlogPost, :count).by(-1)
        end

        it 'redirects to blog posts index' do
          delete :destroy, params: { slug: post_to_destroy.slug }
          expect(response).to redirect_to(blog_posts_path)
        end

        it 'sets the flash notice' do
          delete :destroy, params: { slug: post_to_destroy.slug }
          expect(flash[:notice]).to eq('Blog post was successfully destroyed.')
        end
      end

      context 'as an admin' do
        before { sign_in admin }
        let!(:post_to_destroy) { create(:blog_post, user: user) }

        it 'allows destroying other users posts' do
          expect {
            delete :destroy, params: { slug: post_to_destroy.slug }
          }.to change(BlogPost, :count).by(-1)
        end
      end

      context 'as another user' do
        let(:other_user) { create(:user) }
        before { sign_in other_user }

        it 'redirects with alert' do
          delete :destroy, params: { slug: blog_post.slug }
          expect(response).to redirect_to(blog_posts_path)
          expect(flash[:alert]).to eq('You are not authorized to perform this action.')
        end
      end
    end

    context 'when user is not authenticated' do
        it 'redirects to sign in' do
          delete :destroy, params: { slug: blog_post.slug }
          expect(response).to redirect_to(new_user_session_path)
        end
    end
  end
end
