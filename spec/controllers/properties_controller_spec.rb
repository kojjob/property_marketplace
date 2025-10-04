require 'rails_helper'

RSpec.describe PropertiesController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:property) { create(:property, user: user) }

  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns @properties' do
      active_property = create(:property, status: 'active')
      sold_property = create(:property, status: 'sold')

      get :index
      expect(assigns(:properties)).to include(active_property)
      expect(assigns(:properties)).not_to include(sold_property)
    end

    context 'with filters' do
      let!(:house) { create(:property, property_type: 'House', city: 'New York', price: 500_000, bedrooms: 3) }
      let!(:apartment) { create(:property, property_type: 'Apartment', city: 'Boston', price: 300_000, bedrooms: 2) }

      it 'filters by property type' do
        get :index, params: { property_type: 'House' }
        expect(assigns(:properties)).to include(house)
        expect(assigns(:properties)).not_to include(apartment)
      end

      it 'filters by city' do
        get :index, params: { city: 'Boston' }
        expect(assigns(:properties)).to include(apartment)
        expect(assigns(:properties)).not_to include(house)
      end

      it 'filters by price range' do
        get :index, params: { min_price: 400_000, max_price: 600_000 }
        expect(assigns(:properties)).to include(house)
        expect(assigns(:properties)).not_to include(apartment)
      end

      it 'filters by bedrooms' do
        get :index, params: { bedrooms: 3 }
        expect(assigns(:properties)).to include(house)
        expect(assigns(:properties)).not_to include(apartment)
      end
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { id: property.id }
      expect(response).to be_successful
    end

    it 'assigns the requested property' do
      get :show, params: { id: property.id }
      expect(assigns(:property)).to eq(property)
    end

    context 'when user is signed in' do
      before { sign_in user }

      it 'checks if property is favorited' do
        create(:favorite, user: user, property: property)
        get :show, params: { id: property.id }
        expect(assigns(:is_favorited)).to be true
      end
    end
  end

  describe 'GET #new' do
    context 'when user is not signed in' do
      it 'redirects to sign in' do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is signed in' do
      before { sign_in user }

      it 'returns a success response' do
        get :new
        expect(response).to be_successful
      end

      it 'assigns a new property' do
        get :new
        expect(assigns(:property)).to be_a_new(Property)
        expect(assigns(:property).user).to eq(user)
      end
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) {
      {
        title: 'Test Property',
        description: 'A test property',
        price: 100_000,
        property_type: 'House',
        bedrooms: 3,
        bathrooms: 2,
        square_feet: 1500,
        address: '123 Test St',
        city: 'Test City',
        state: 'TS',
        zip_code: '12345'
      }
    }

    context 'when user is not signed in' do
      it 'redirects to sign in' do
        post :create, params: { property: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is signed in' do
      before { sign_in user }

      context 'with valid params' do
        it 'creates a new Property' do
          expect {
            post :create, params: { property: valid_attributes }
          }.to change(Property, :count).by(1)
        end

        it 'redirects to the created property' do
          post :create, params: { property: valid_attributes }
          expect(response).to redirect_to(Property.last)
        end

        context 'with image uploads' do
          let(:image_file) { fixture_file_upload('spec/fixtures/test_image.jpg', 'image/jpeg') }
          let(:attributes_with_images) { valid_attributes.merge(images: [ image_file ]) }

          it 'creates property with attached images' do
            post :create, params: { property: attributes_with_images }
            property = Property.last
            expect(property.images.count).to eq(1)
            expect(property.images.first.content_type).to eq('image/jpeg')
          end

          it 'handles multiple image uploads' do
            image1 = fixture_file_upload('spec/fixtures/test_image.jpg', 'image/jpeg')
            image2 = fixture_file_upload('spec/fixtures/test_image2.jpg', 'image/jpeg')
            attributes_with_multiple_images = valid_attributes.merge(images: [ image1, image2 ])

            post :create, params: { property: attributes_with_multiple_images }
            property = Property.last
            expect(property.images.count).to eq(2)
          end
        end
      end

      context 'with invalid params' do
        let(:invalid_attributes) { { title: '', description: '' } }

        it 'does not create a new Property' do
          expect {
            post :create, params: { property: invalid_attributes }
          }.not_to change(Property, :count)
        end

        it 'renders the new template with unprocessable_entity status' do
          post :create, params: { property: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:new)
        end
      end
    end
  end

  describe 'GET #edit' do
    context 'when user is not signed in' do
      it 'redirects to sign in' do
        get :edit, params: { id: property.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is signed in' do
      context 'as owner' do
        before { sign_in user }

        it 'returns a success response' do
          get :edit, params: { id: property.id }
          expect(response).to be_successful
        end

        it 'assigns the requested property' do
          get :edit, params: { id: property.id }
          expect(assigns(:property)).to eq(property)
        end
      end

      context 'as different user' do
        before { sign_in other_user }

        it 'redirects to properties index' do
          get :edit, params: { id: property.id }
          expect(response).to redirect_to(properties_path)
        end
      end
    end
  end

  describe 'PATCH #update' do
    context 'when user is not signed in' do
      it 'redirects to sign in' do
        patch :update, params: { id: property.id, property: { title: 'New Title' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is signed in' do
      context 'as owner' do
        before { sign_in user }

        context 'with valid params' do
          let(:new_attributes) { { title: 'Updated Title', price: 200_000 } }

          it 'updates the requested property' do
            patch :update, params: { id: property.id, property: new_attributes }
            property.reload
            expect(property.title).to eq('Updated Title')
            expect(property.price).to eq(200_000)
          end

          it 'redirects to the property' do
            patch :update, params: { id: property.id, property: new_attributes }
            expect(response).to redirect_to(property)
          end
        end

        context 'with invalid params' do
          let(:invalid_attributes) { { title: '', price: -100 } }

          it 'does not update the property' do
            original_title = property.title
            patch :update, params: { id: property.id, property: invalid_attributes }
            property.reload
            expect(property.title).to eq(original_title)
          end

          it 'renders the edit template with unprocessable_entity status' do
            patch :update, params: { id: property.id, property: invalid_attributes }
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response).to render_template(:edit)
          end
        end
      end

      context 'as different user' do
        before { sign_in other_user }

        it 'does not update the property' do
          original_title = property.title
          patch :update, params: { id: property.id, property: { title: 'Hacked!' } }
          property.reload
          expect(property.title).to eq(original_title)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user is not signed in' do
      it 'redirects to sign in' do
        delete :destroy, params: { id: property.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is signed in' do
      context 'as owner' do
        before { sign_in user }

        it 'destroys the property' do
          property # create the property first
          expect {
            delete :destroy, params: { id: property.id }
          }.to change(Property, :count).by(-1)
        end

        it 'redirects to properties index' do
          delete :destroy, params: { id: property.id }
          expect(response).to redirect_to(properties_path)
        end
      end

      context 'as different user' do
        before { sign_in other_user }

        it 'does not destroy the property' do
          property # create the property first
          expect {
            delete :destroy, params: { id: property.id }
          }.not_to change(Property, :count)
        end
      end
    end
  end

  describe 'POST #favorite' do
    context 'when user is not signed in' do
      it 'redirects to sign in' do
        post :favorite, params: { id: property.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is signed in' do
      before { sign_in user }

      it 'creates a favorite' do
        expect {
          post :favorite, params: { id: property.id }
        }.to change(Favorite, :count).by(1)
      end

      it 'redirects back' do
        request.env['HTTP_REFERER'] = properties_path
        post :favorite, params: { id: property.id }
        expect(response).to redirect_to(properties_path)
      end
    end
  end

  describe 'DELETE #unfavorite' do
    context 'when user is not signed in' do
      it 'redirects to sign in' do
        delete :unfavorite, params: { id: property.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is signed in' do
      before { sign_in user }

      it 'destroys the favorite' do
        create(:favorite, user: user, property: property)
        expect {
          delete :unfavorite, params: { id: property.id }
        }.to change(Favorite, :count).by(-1)
      end

      it 'redirects back' do
        request.env['HTTP_REFERER'] = properties_path
        create(:favorite, user: user, property: property)
        delete :unfavorite, params: { id: property.id }
        expect(response).to redirect_to(properties_path)
      end
    end
  end
end
