require 'rails_helper'

RSpec.describe ProfilesController, type: :controller do
  let(:user) { create(:user) }
  let(:profile) { create(:profile, user: user) }
  let(:other_user) { create(:user) }
  let(:other_profile) { create(:profile, user: other_user) }

  describe 'authentication' do
    context 'when user is not signed in' do
      it 'redirects to sign in for show action' do
        get :show, params: { id: profile.id }
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects to sign in for edit action' do
        get :edit, params: { id: profile.id }
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects to sign in for update action' do
        patch :update, params: { id: profile.id, profile: { first_name: 'Updated' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET #show' do
    before { sign_in(user) }

    context 'when profile exists' do
      it 'returns a success response' do
        get :show, params: { id: profile.id }
        expect(response).to be_successful
      end

      it 'assigns the requested profile to @profile' do
        get :show, params: { id: profile.id }
        expect(assigns(:profile)).to eq(profile)
      end

      it 'renders the show template' do
        get :show, params: { id: profile.id }
        expect(response).to render_template(:show)
      end
    end

    context 'when profile does not exist' do
      it 'redirects to home page' do
        get :show, params: { id: 999999 }
        expect(response).to redirect_to(root_path)
      end

      it 'sets an alert flash message' do
        get :show, params: { id: 999999 }
        expect(flash[:alert]).to eq('Profile not found.')
      end
    end

    context 'when viewing another user\'s profile' do
      it 'allows viewing other profiles' do
        get :show, params: { id: other_profile.id }
        expect(response).to be_successful
        expect(assigns(:profile)).to eq(other_profile)
      end
    end
  end

  describe 'GET #edit' do
    before { sign_in(user) }

    context 'when editing own profile' do
      it 'returns a success response' do
        get :edit, params: { id: profile.id }
        expect(response).to be_successful
      end

      it 'assigns the profile to @profile' do
        get :edit, params: { id: profile.id }
        expect(assigns(:profile)).to eq(profile)
      end

      it 'renders the edit template' do
        get :edit, params: { id: profile.id }
        expect(response).to render_template(:edit)
      end
    end

    context 'when trying to edit another user\'s profile' do
      it 'redirects to home page' do
        get :edit, params: { id: other_profile.id }
        expect(response).to redirect_to(root_path)
      end

      it 'sets an alert flash message' do
        get :edit, params: { id: other_profile.id }
        expect(flash[:alert]).to eq('You can only edit your own profile.')
      end
    end

    context 'when profile does not exist' do
      it 'redirects to home page' do
        get :edit, params: { id: 999999 }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH #update' do
    before { sign_in(user) }

    context 'when updating own profile with valid params' do
      let(:valid_attributes) do
        {
          first_name: 'Updated',
          last_name: 'Name',
          bio: 'Updated bio',
          company_name: 'New Company',
          position: 'Senior Agent',
          years_experience: 15,
          languages: 'English, French',
          address: '456 New St',
          city: 'Boston',
          state: 'MA',
          country: 'USA',
          website: 'https://updated.com',
          facebook_url: 'https://facebook.com/updated',
          twitter_url: 'https://twitter.com/updated',
          linkedin_url: 'https://linkedin.com/in/updated',
          instagram_url: 'https://instagram.com/updated'
        }
      end

      it 'updates the profile' do
        patch :update, params: { id: profile.id, profile: valid_attributes }
        profile.reload
        expect(profile.first_name).to eq('Updated')
        expect(profile.last_name).to eq('Name')
        expect(profile.bio).to eq('Updated bio')
        expect(profile.company_name).to eq('New Company')
        expect(profile.position).to eq('Senior Agent')
        expect(profile.years_experience).to eq(15)
        expect(profile.languages).to eq('English, French')
        expect(profile.address).to eq('456 New St')
        expect(profile.city).to eq('Boston')
        expect(profile.state).to eq('MA')
        expect(profile.country).to eq('USA')
        expect(profile.website).to eq('https://updated.com')
        expect(profile.facebook_url).to eq('https://facebook.com/updated')
        expect(profile.twitter_url).to eq('https://twitter.com/updated')
        expect(profile.linkedin_url).to eq('https://linkedin.com/in/updated')
        expect(profile.instagram_url).to eq('https://instagram.com/updated')
      end

      it 'redirects to the profile' do
        patch :update, params: { id: profile.id, profile: valid_attributes }
        expect(response).to redirect_to(profile_path(profile))
      end

      it 'sets a success flash message' do
        patch :update, params: { id: profile.id, profile: valid_attributes }
        expect(flash[:notice]).to eq('Profile was successfully updated.')
      end
    end

    context 'when updating with invalid params' do
      let(:invalid_attributes) do
        {
          first_name: '',
          last_name: '',
          phone_number: 'invalid'
        }
      end

      it 'does not update the profile' do
        original_first_name = profile.first_name
        patch :update, params: { id: profile.id, profile: invalid_attributes }
        profile.reload
        expect(profile.first_name).to eq(original_first_name)
      end

      it 're-renders the edit template' do
        patch :update, params: { id: profile.id, profile: invalid_attributes }
        expect(response).to render_template(:edit)
      end

      it 'returns unprocessable entity status' do
        patch :update, params: { id: profile.id, profile: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when trying to update another user\'s profile' do
      it 'redirects to home page' do
        patch :update, params: { id: other_profile.id, profile: { first_name: 'Hacked' } }
        expect(response).to redirect_to(root_path)
      end

      it 'does not update the profile' do
        original_name = other_profile.first_name
        patch :update, params: { id: other_profile.id, profile: { first_name: 'Hacked' } }
        other_profile.reload
        expect(other_profile.first_name).to eq(original_name)
      end

      it 'sets an alert flash message' do
        patch :update, params: { id: other_profile.id, profile: { first_name: 'Hacked' } }
        expect(flash[:alert]).to eq('You can only edit your own profile.')
      end
    end

    context 'when profile does not exist' do
      it 'redirects to home page' do
        patch :update, params: { id: 999999, profile: { first_name: 'Test' } }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'private methods' do
    describe '#profile_params' do
      it 'permits the correct parameters' do
        params = ActionController::Parameters.new(
          profile: {
            first_name: 'John',
            last_name: 'Doe',
            phone_number: '+1234567890',
            bio: 'Bio text',
            role: 'agent',
            company_name: 'ABC Realty',
            position: 'Senior Agent',
            years_experience: 10,
            languages: 'English, Spanish',
            address: '123 Main St',
            city: 'New York',
            state: 'NY',
            country: 'USA',
            website: 'https://johndoe.com',
            facebook_url: 'https://facebook.com/johndoe',
            twitter_url: 'https://twitter.com/johndoe',
            linkedin_url: 'https://linkedin.com/in/johndoe',
            instagram_url: 'https://instagram.com/johndoe',
            avatar: 'avatar_data'
          }
        )

        controller.params = params
        permitted_params = controller.send(:profile_params)

        expect(permitted_params.keys).to include(
          'first_name', 'last_name', 'phone_number', 'bio',
          'company_name', 'position', 'years_experience', 'languages',
          'address', 'city', 'state', 'country', 'website',
          'facebook_url', 'twitter_url', 'linkedin_url', 'instagram_url',
          'avatar'
        )
      end
    end
  end
end
