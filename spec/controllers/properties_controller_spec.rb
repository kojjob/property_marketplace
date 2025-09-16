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
      before { sign_in(user) }

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
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when user is signed in' do
      before { sign_in(user) }

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
      attributes_for(:property).merge(user_id: user.id)
    }

    let(:invalid_attributes) {
      { title: '', price: nil }
    }

    context 'when user is not signed in' do
      it 'redirects to sign in' do
        post :create, params: { property: valid_attributes }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when user is signed in' do
      before { sign_in(user) }

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

        it 'sets a success notice' do
          post :create, params: { property: valid_attributes }
          expect(flash[:notice]).to eq('Property was successfully listed.')
        end
      end

      context 'with invalid params' do
        it 'does not create a new Property' do
          expect {
            post :create, params: { property: invalid_attributes }
          }.to change(Property, :count).by(0)
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
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when user is signed in' do
      context 'as the property owner' do
        before { sign_in(user) }

        it 'returns a success response' do
          get :edit, params: { id: property.id }
          expect(response).to be_successful
        end
      end

      context 'as a different user' do
        before { sign_in(other_user) }

        it 'redirects to properties index' do
          get :edit, params: { id: property.id }
          expect(response).to redirect_to(properties_path)
        end
      end
    end
  end

  describe 'PATCH #update' do
    let(:new_attributes) {
      { title: 'Updated Title', price: 750_000 }
    }

    context 'when user is not signed in' do
      it 'redirects to sign in' do
        patch :update, params: { id: property.id, property: new_attributes }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when user is signed in as owner' do
      before { sign_in(user) }

      context 'with valid params' do
        it 'updates the property' do
          patch :update, params: { id: property.id, property: new_attributes }
          property.reload
          expect(property.title).to eq('Updated Title')
          expect(property.price).to eq(750_000)
        end

        it 'redirects to the property' do
          patch :update, params: { id: property.id, property: new_attributes }
          expect(response).to redirect_to(property)
        end
      end

      context 'with invalid params' do
        it 'does not update the property' do
          patch :update, params: { id: property.id, property: { title: '', price: nil } }
          property.reload
          expect(property.title).not_to eq('')
        end

        it 'renders the edit template with unprocessable_entity status' do
          patch :update, params: { id: property.id, property: { title: '', price: nil } }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:edit)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    before { property } # Create the property

    context 'when user is not signed in' do
      it 'redirects to sign in' do
        delete :destroy, params: { id: property.id }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when user is signed in as owner' do
      before { sign_in(user) }

      it 'destroys the property' do
        expect {
          delete :destroy, params: { id: property.id }
        }.to change(Property, :count).by(-1)
      end

      it 'redirects to properties index' do
        delete :destroy, params: { id: property.id }
        expect(response).to redirect_to(properties_path)
      end
    end

    context 'when user is signed in as different user' do
      before do
        allow(controller).to receive(:signed_in?).and_return(true)
        allow(controller).to receive(:current_user).and_return(other_user)
      end

      it 'does not destroy the property' do
        expect {
          delete :destroy, params: { id: property.id }
        }.to change(Property, :count).by(0)
      end
    end
  end

  describe 'POST #favorite' do
    context 'when user is not signed in' do
      it 'redirects to sign in' do
        post :favorite, params: { id: property.id }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when user is signed in' do
      before do
        sign_in(user)
        request.env["HTTP_REFERER"] = property_path(property)
      end

      it 'creates a favorite' do
        expect {
          post :favorite, params: { id: property.id }
        }.to change(Favorite, :count).by(1)
      end

      it 'redirects back' do
        post :favorite, params: { id: property.id }
        expect(response).to redirect_to(property_path(property))
      end
    end
  end

  describe 'DELETE #unfavorite' do
    let!(:favorite) { create(:favorite, user: user, property: property) }

    context 'when user is not signed in' do
      it 'redirects to sign in' do
        delete :unfavorite, params: { id: property.id }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when user is signed in' do
      before do
        sign_in(user)
        request.env["HTTP_REFERER"] = property_path(property)
      end

      it 'destroys the favorite' do
        expect {
          delete :unfavorite, params: { id: property.id }
        }.to change(Favorite, :count).by(-1)
      end

      it 'redirects back' do
        delete :unfavorite, params: { id: property.id }
        expect(response).to redirect_to(property_path(property))
      end
    end
  end
end