require 'rails_helper'

RSpec.describe CommentsController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let(:blog_post) { create(:blog_post, :published) }
  let(:comment) { create(:comment, blog_post: blog_post, user: user) }
  let(:approved_comment) { create(:comment, :approved, blog_post: blog_post) }

  describe 'POST #create' do
    context 'when user is authenticated' do
      before { sign_in_user user }

      context 'with valid params' do
        let(:valid_params) do
          {
            blog_post_id: blog_post.slug,
            comment: { content: 'Great post!' }
          }
        end

        it 'creates a new comment' do
          expect {
            post :create, params: valid_params
          }.to change(Comment, :count).by(1)
        end

        it 'assigns the comment to the current user' do
          post :create, params: valid_params
          expect(Comment.last.user).to eq(user)
        end

        it 'assigns the comment to the blog post' do
          post :create, params: valid_params
          expect(Comment.last.blog_post).to eq(blog_post)
        end

        it 'redirects to the blog post' do
          post :create, params: valid_params
          expect(response).to redirect_to(blog_post)
        end

        context 'as a reply to an approved comment' do
          let(:reply_params) do
            {
              blog_post_id: blog_post.slug,
              comment: { content: 'Reply!', parent_id: approved_comment.id }
            }
          end

          it 'auto-approves the reply' do
            post :create, params: reply_params
            expect(Comment.last.approved?).to be true
          end
        end

        context 'with turbo stream format' do
          it 'responds with turbo stream' do
            post :create, params: valid_params, format: :turbo_stream
            expect(response.media_type).to eq('text/vnd.turbo-stream.html')
          end
        end

        context 'with json format' do
          it 'responds with json' do
            post :create, params: valid_params, format: :json
            expect(response).to have_http_status(:created)
            expect(JSON.parse(response.body)['content']).to eq('Great post!')
          end
        end
      end

      context 'with invalid params' do
        let(:invalid_params) do
          {
            blog_post_id: blog_post.slug,
            comment: { content: '' }
          }
        end

        it 'does not create a comment' do
          expect {
            post :create, params: invalid_params
          }.not_to change(Comment, :count)
        end

        it 'renders the blog post show template' do
          post :create, params: invalid_params
          expect(response).to render_template('blog_posts/show')
        end

        it 'returns unprocessable entity status' do
          post :create, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        context 'with turbo stream format' do
          it 'replaces the comment form' do
            post :create, params: invalid_params, format: :turbo_stream
            expect(response.body).to include('turbo-stream')
            expect(response.body).to include('comment_form')
          end
        end
      end
    end

    context 'when user is not authenticated' do
      let(:guest_params) do
        {
          blog_post_id: blog_post.slug,
          comment: { content: 'Great post!', author_name: 'Guest', author_email: 'guest@example.com' }
        }
      end

      it 'creates a comment without user association' do
        expect {
          post :create, params: guest_params
        }.to change(Comment, :count).by(1)
      end

      it 'sets author information' do
        post :create, params: guest_params
        comment = Comment.last
        expect(comment.author_name).to eq('Guest')
        expect(comment.author_email).to eq('guest@example.com')
        expect(comment.user).to be_nil
      end
    end
  end

  describe 'PATCH #update' do
    context 'when user is authenticated' do
      context 'as the comment owner' do
        before { sign_in_user user }

        context 'with valid params' do
          let(:update_params) do
            {
              id: comment.id,
              comment: { content: 'Updated comment' }
            }
          end

          it 'updates the comment' do
            expect {
              patch :update, params: update_params
            }.to change { comment.reload.content }.to('Updated comment')
          end

          it 'redirects to the blog post' do
            patch :update, params: update_params
            expect(response).to redirect_to(comment.blog_post)
          end

          context 'with turbo stream format' do
            it 'responds with turbo stream' do
              patch :update, params: update_params, format: :turbo_stream
              expect(response.media_type).to eq('text/vnd.turbo-stream.html')
            end
          end

          context 'with json format' do
            it 'responds with json' do
              patch :update, params: update_params, format: :json
              expect(response).to have_http_status(:ok)
            end
          end
        end

        context 'with invalid params' do
          let(:invalid_params) do
            {
              id: comment.id,
              comment: { content: '' }
            }
          end

          it 'does not update the comment' do
            expect {
              patch :update, params: invalid_params
            }.not_to change { comment.reload.content }
            end

          it 'renders the blog post show template' do
            patch :update, params: invalid_params
            expect(response).to render_template('blog_posts/show')
          end

          context 'with turbo stream format' do
            it 'replaces the comment' do
              patch :update, params: invalid_params, format: :turbo_stream
              expect(response.body).to include('turbo-stream')
              expect(response.body).to include(comment.id.to_s)
            end
          end
        end
      end

      context 'as an admin' do
        before { sign_in_user admin }

        it 'allows updating other users comments' do
          patch :update, params: { id: comment.id, comment: { content: 'Admin updated' } }
          expect(comment.reload.content).to eq('Admin updated')
        end
      end

      context 'as another user' do
        let(:other_user) { create(:user) }
        before { sign_in_user other_user }

        it 'redirects with alert' do
          patch :update, params: { id: comment.id, comment: { content: 'Hacked' } }
          expect(response).to redirect_to(comment.blog_post)
          expect(flash[:alert]).to eq('You are not authorized to perform this action.')
        end
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        patch :update, params: { id: comment.id, comment: { content: 'Test' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user is authenticated' do
      context 'as the comment owner' do
        before { sign_in_user user }

        it 'destroys the comment' do
          comment # create the comment
          expect {
            delete :destroy, params: { id: comment.id }
          }.to change(Comment, :count).by(-1)
        end

        it 'redirects to the blog post' do
          delete :destroy, params: { id: comment.id }
          expect(response).to redirect_to(comment.blog_post)
        end

        context 'with turbo stream format' do
          it 'responds with turbo stream' do
            delete :destroy, params: { id: comment.id }, format: :turbo_stream
            expect(response.media_type).to eq('text/vnd.turbo-stream.html')
          end
        end

        context 'with json format' do
          it 'responds with no content' do
            delete :destroy, params: { id: comment.id }, format: :json
            expect(response).to have_http_status(:no_content)
          end
        end
      end

      context 'as an admin' do
        before { sign_in_user admin }

        it 'allows destroying other users comments' do
          comment # create the comment
          expect {
            delete :destroy, params: { id: comment.id }
          }.to change(Comment, :count).by(-1)
        end
      end

      context 'as another user' do
        let(:other_user) { create(:user) }
        before { sign_in_user other_user }

        it 'redirects with alert' do
          delete :destroy, params: { id: comment.id }
          expect(response).to redirect_to(comment.blog_post)
          expect(flash[:alert]).to eq('You are not authorized to perform this action.')
        end
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        delete :destroy, params: { id: comment.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH #approve' do
    context 'when user is admin' do
      before { sign_in admin }

      it 'approves the comment' do
        expect {
          patch :approve, params: { id: comment.id }
        }.to change { comment.reload.status }.from('pending').to('approved')
      end

      it 'redirects to the blog post' do
        patch :approve, params: { id: comment.id }
        expect(response).to redirect_to(comment.blog_post)
      end

      it 'sets the flash notice' do
        patch :approve, params: { id: comment.id }
        expect(flash[:notice]).to eq('Comment was approved.')
      end

      context 'with turbo stream format' do
        it 'responds with turbo stream' do
          patch :approve, params: { id: comment.id }, format: :turbo_stream
          expect(response.media_type).to eq('text/vnd.turbo-stream.html')
        end
      end

      context 'with json format' do
        it 'responds with json' do
          patch :approve, params: { id: comment.id }, format: :json
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'when user is not admin' do
      before { sign_in user }

      it 'redirects with alert' do
        patch :approve, params: { id: comment.id }
        expect(response).to redirect_to(comment.blog_post)
        expect(flash[:alert]).to eq('You are not authorized to moderate comments.')
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        patch :approve, params: { id: comment.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH #reject' do
    context 'when user is admin' do
      before { sign_in admin }

      it 'rejects the comment' do
        expect {
          patch :reject, params: { id: comment.id }
        }.to change { comment.reload.status }.from('pending').to('rejected')
      end

      it 'redirects to the blog post' do
        patch :reject, params: { id: comment.id }
        expect(response).to redirect_to(comment.blog_post)
      end

      it 'sets the flash notice' do
        patch :reject, params: { id: comment.id }
        expect(flash[:notice]).to eq('Comment was rejected.')
      end

      context 'with turbo stream format' do
        it 'responds with turbo stream' do
          patch :reject, params: { id: comment.id }, format: :turbo_stream
          expect(response.media_type).to eq('text/vnd.turbo-stream.html')
        end
      end

      context 'with json format' do
        it 'responds with json' do
          patch :reject, params: { id: comment.id }, format: :json
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'when user is not admin' do
      before { sign_in user }

      it 'redirects with alert' do
        patch :reject, params: { id: comment.id }
        expect(response).to redirect_to(comment.blog_post)
        expect(flash[:alert]).to eq('You are not authorized to moderate comments.')
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        patch :reject, params: { id: comment.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
