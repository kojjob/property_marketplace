require 'rails_helper'

RSpec.describe PagesController, type: :controller do
  describe 'GET #home' do
    context 'when there are featured properties' do
      let!(:featured_properties) { create_list(:property, 3, featured: true, status: 'active') }
      let!(:non_featured_properties) { create_list(:property, 2, featured: false, status: 'active') }

      before do
        # Create property images for the featured properties
        featured_properties.each do |property|
          create(:property_image, property: property)
        end
      end

      it 'returns a success response' do
        get :home
        expect(response).to be_successful
      end

      it 'assigns featured properties' do
        get :home
        expect(assigns(:featured_properties)).to match_array(featured_properties)
        expect(assigns(:featured_properties)).not_to include(*non_featured_properties)
      end

      it 'includes property images and user associations' do
        get :home
        # Check that the query includes the associations
        expect(assigns(:featured_properties).first.association(:property_images)).to be_loaded
        expect(assigns(:featured_properties).first.association(:user)).to be_loaded
      end

      it 'limits results to 6 properties' do
        create_list(:property, 5, featured: true, status: 'active')
        get :home
        expect(assigns(:featured_properties).count).to eq(6)
      end
    end

    context 'when there are no featured properties' do
      let!(:recent_properties) { create_list(:property, 4, featured: false, status: 'active') }

      before do
        # Create property images for the recent properties
        recent_properties.each do |property|
          create(:property_image, property: property)
        end
      end

      it 'falls back to recent properties' do
        get :home
        expect(assigns(:featured_properties)).to match_array(recent_properties)
      end

      it 'orders by created_at desc' do
        older_property = create(:property, featured: false, status: 'active', created_at: 2.days.ago)
        newer_property = create(:property, featured: false, status: 'active', created_at: 1.hour.ago)

        get :home
        featured_properties = assigns(:featured_properties)
        newer_index = featured_properties.index(newer_property)
        older_index = featured_properties.index(older_property)

        expect(newer_index).to be < older_index if newer_index && older_index
      end
    end

    context 'when no properties exist' do
      it 'assigns empty collection' do
        get :home
        expect(assigns(:featured_properties)).to be_empty
      end

      it 'still returns successful response' do
        get :home
        expect(response).to be_successful
      end
    end

    it 'renders the home template' do
      get :home
      expect(response).to render_template(:home)
    end

    it 'does not require authentication' do
      get :home
      expect(response).not_to redirect_to(new_user_session_path)
    end
  end
end
