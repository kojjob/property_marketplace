require 'rails_helper'

RSpec.describe ListingsController, type: :controller do
  let(:user) { create(:user) }
  let(:property) { create(:property, user: user) }
  let(:listing) { create(:listing, property: property, user: user) }

  describe 'GET #index' do
    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns active listings to @listings' do
      active_listing = create(:listing, status: 'active')
      inactive_listing = create(:listing, status: 'inactive')

      get :index
      expect(assigns(:listings)).to include(active_listing)
      expect(assigns(:listings)).not_to include(inactive_listing)
    end

    context 'with search parameters' do
      it 'filters by location' do
        london_listing = create(:listing, property: create(:property, city: 'London'))
        paris_listing = create(:listing, property: create(:property, city: 'Paris'))

        get :index, params: { location: 'London' }
        expect(assigns(:listings)).to include(london_listing)
        expect(assigns(:listings)).not_to include(paris_listing)
      end

      it 'filters by price range' do
        cheap_listing = create(:listing, price_per_night: 50)
        expensive_listing = create(:listing, price_per_night: 200)

        get :index, params: { min_price: 100, max_price: 150 }
        expect(assigns(:listings)).not_to include(cheap_listing)
        expect(assigns(:listings)).not_to include(expensive_listing)
      end

      it 'filters by listing type' do
        rent_listing = create(:listing, listing_type: 'rent')
        sale_listing = create(:listing, listing_type: 'sale')

        get :index, params: { listing_type: 'rent' }
        expect(assigns(:listings)).to include(rent_listing)
        expect(assigns(:listings)).not_to include(sale_listing)
      end
    end
  end

  describe 'GET #show' do
    it 'returns a successful response' do
      get :show, params: { id: listing.id }
      expect(response).to be_successful
    end

    it 'assigns the requested listing to @listing' do
      get :show, params: { id: listing.id }
      expect(assigns(:listing)).to eq(listing)
    end

    it 'assigns related listings to @related_listings' do
      related_listing = create(:listing, property: create(:property, city: property.city))
      different_listing = create(:listing, property: create(:property, city: 'Different City'))

      get :show, params: { id: listing.id }
      expect(assigns(:related_listings)).to include(related_listing)
      expect(assigns(:related_listings)).not_to include(different_listing)
    end
  end

  describe 'GET #new' do
    context 'when user is signed in' do
      before { sign_in user }

      it 'returns a successful response' do
        get :new
        expect(response).to be_successful
      end

      it 'assigns a new listing to @listing' do
        get :new
        expect(assigns(:listing)).to be_a_new(Listing)
      end

      it 'assigns user properties to @properties' do
        property1 = create(:property, user: user)
        property2 = create(:property, user: user)
        other_property = create(:property)

        get :new
        expect(assigns(:properties)).to include(property1, property2)
        expect(assigns(:properties)).not_to include(other_property)
      end
    end

    context 'when user is not signed in' do
      it 'redirects to sign in page' do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST #create' do
    context 'when user is signed in' do
      before { sign_in user }

      context 'with valid parameters' do
        let(:valid_attributes) do
          {
            property_id: property.id,
            title: 'Beautiful Apartment',
            description: 'A lovely place to stay',
            price_per_night: 100,
            listing_type: 'rent',
            status: 'active'
          }
        end

        it 'creates a new Listing' do
          expect {
            post :create, params: { listing: valid_attributes }
          }.to change(Listing, :count).by(1)
        end

        it 'redirects to the created listing' do
          post :create, params: { listing: valid_attributes }
          expect(response).to redirect_to(Listing.last)
        end

        it 'sets a success flash message' do
          post :create, params: { listing: valid_attributes }
          expect(flash[:notice]).to eq('Listing was successfully created.')
        end
      end

      context 'with invalid parameters' do
        let(:invalid_attributes) do
          {
            property_id: nil,
            title: '',
            price_per_night: -100
          }
        end

        it 'does not create a new Listing' do
          expect {
            post :create, params: { listing: invalid_attributes }
          }.not_to change(Listing, :count)
        end

        it 'renders the new template' do
          post :create, params: { listing: invalid_attributes }
          expect(response).to render_template(:new)
        end
      end
    end
  end

  describe 'GET #edit' do
    context 'when user owns the listing' do
      before { sign_in user }

      it 'returns a successful response' do
        get :edit, params: { id: listing.id }
        expect(response).to be_successful
      end

      it 'assigns the requested listing to @listing' do
        get :edit, params: { id: listing.id }
        expect(assigns(:listing)).to eq(listing)
      end
    end

    context 'when user does not own the listing' do
      let(:other_user) { create(:user) }
      before { sign_in other_user }

      it 'redirects to listings page' do
        get :edit, params: { id: listing.id }
        expect(response).to redirect_to(listings_path)
      end

      it 'sets an error flash message' do
        get :edit, params: { id: listing.id }
        expect(flash[:alert]).to eq('You are not authorized to edit this listing.')
      end
    end
  end

  describe 'PATCH #update' do
    context 'when user owns the listing' do
      before { sign_in user }

      context 'with valid parameters' do
        let(:new_attributes) do
          {
            title: 'Updated Title',
            price_per_night: 150
          }
        end

        it 'updates the requested listing' do
          patch :update, params: { id: listing.id, listing: new_attributes }
          listing.reload
          expect(listing.title).to eq('Updated Title')
          expect(listing.price_per_night).to eq(150)
        end

        it 'redirects to the listing' do
          patch :update, params: { id: listing.id, listing: new_attributes }
          expect(response).to redirect_to(listing)
        end

        it 'sets a success flash message' do
          patch :update, params: { id: listing.id, listing: new_attributes }
          expect(flash[:notice]).to eq('Listing was successfully updated.')
        end
      end

      context 'with invalid parameters' do
        let(:invalid_attributes) do
          {
            title: '',
            price_per_night: -100
          }
        end

        it 'does not update the listing' do
          original_title = listing.title
          patch :update, params: { id: listing.id, listing: invalid_attributes }
          listing.reload
          expect(listing.title).to eq(original_title)
        end

        it 'renders the edit template' do
          patch :update, params: { id: listing.id, listing: invalid_attributes }
          expect(response).to render_template(:edit)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user owns the listing' do
      before { sign_in user }

      it 'destroys the requested listing' do
        listing # create the listing
        expect {
          delete :destroy, params: { id: listing.id }
        }.to change(Listing, :count).by(-1)
      end

      it 'redirects to the listings list' do
        delete :destroy, params: { id: listing.id }
        expect(response).to redirect_to(listings_path)
      end

      it 'sets a success flash message' do
        delete :destroy, params: { id: listing.id }
        expect(flash[:notice]).to eq('Listing was successfully deleted.')
      end
    end

    context 'when user does not own the listing' do
      let(:other_user) { create(:user) }
      before { sign_in other_user }

      it 'does not destroy the listing' do
        listing # create the listing
        expect {
          delete :destroy, params: { id: listing.id }
        }.not_to change(Listing, :count)
      end

      it 'redirects to listings page' do
        delete :destroy, params: { id: listing.id }
        expect(response).to redirect_to(listings_path)
      end
    end
  end
end