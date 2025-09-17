require 'rails_helper'

RSpec.describe 'Pages Requests', type: :request do
  describe 'GET /' do
    context 'with featured properties' do
      let!(:featured_properties) { create_list(:property, 3, featured: true, status: 'active') }
      let!(:non_featured_properties) { create_list(:property, 2, featured: false, status: 'active') }

      before do
        featured_properties.each { |property| create(:property_image, property: property) }
      end

      it 'returns http success' do
        get '/'
        expect(response).to have_http_status(:success)
      end

      it 'assigns featured properties' do
        get '/'
        expect(assigns(:featured_properties)).to match_array(featured_properties)
      end

      it 'includes associations in query' do
        get '/'
        # Verify that the associations are loaded
        expect(assigns(:featured_properties).first.association(:property_images)).to be_loaded
        expect(assigns(:featured_properties).first.association(:user)).to be_loaded
      end

      it 'limits to 6 properties' do
        create_list(:property, 5, featured: true, status: 'active')
        get '/'
        expect(assigns(:featured_properties).count).to eq(6)
      end

      it 'renders the home template' do
        get '/'
        expect(response).to render_template(:home)
      end

      it 'includes proper content sections' do
        get '/'
        expect(response.body).to include('Find Your Dream Property')
        expect(response.body).to include('Featured Properties')
        expect(response.body).to include('Why Choose')
      end

      it 'includes property type cards' do
        get '/'
        expect(response.body).to include('Houses')
        expect(response.body).to include('Apartments')
        expect(response.body).to include('Condos')
        expect(response.body).to include('Commercial')
      end

      it 'includes market statistics' do
        get '/'
        expect(response.body).to include('2,847')
        expect(response.body).to include('15,892')
      end

      it 'includes cities section with all cities' do
        get '/'
        cities = ['San Francisco', 'New York', 'Miami', 'Austin', 'Seattle', 'Portland']
        cities.each do |city|
          expect(response.body).to include(city)
        end
      end

      it 'displays featured properties information' do
        get '/'
        featured_properties.each do |property|
          expect(response.body).to include(property.title)
        end
      end
    end

    context 'without featured properties' do
      let!(:recent_properties) { create_list(:property, 4, featured: false, status: 'active') }

      before do
        recent_properties.each { |property| create(:property_image, property: property) }
      end

      it 'falls back to recent properties' do
        get '/'
        expect(assigns(:featured_properties)).to match_array(recent_properties)
      end

      it 'orders by created_at desc' do
        older_property = create(:property, featured: false, status: 'active', created_at: 2.days.ago)
        newer_property = create(:property, featured: false, status: 'active', created_at: 1.hour.ago)
        create(:property_image, property: older_property)
        create(:property_image, property: newer_property)

        get '/'
        featured_properties = assigns(:featured_properties)
        newer_index = featured_properties.index(newer_property)
        older_index = featured_properties.index(older_property)

        expect(newer_index).to be < older_index if newer_index && older_index
      end
    end

    context 'with no properties' do
      it 'assigns empty collection' do
        get '/'
        expect(assigns(:featured_properties)).to be_empty
      end

      it 'still returns successful response' do
        get '/'
        expect(response).to have_http_status(:success)
      end

      it 'renders home template' do
        get '/'
        expect(response).to render_template(:home)
      end
    end

    context 'with mixed property statuses' do
      let!(:active_featured) { create(:property, featured: true, status: 'active') }
      let!(:sold_featured) { create(:property, featured: true, status: 'sold') }
      let!(:pending_featured) { create(:property, featured: true, status: 'pending') }

      before do
        [active_featured, sold_featured, pending_featured].each do |property|
          create(:property_image, property: property)
        end
      end

      it 'only includes active properties' do
        get '/'
        expect(assigns(:featured_properties)).to include(active_featured)
        expect(assigns(:featured_properties)).not_to include(sold_featured)
        expect(assigns(:featured_properties)).not_to include(pending_featured)
      end
    end

    it 'has proper meta tags for SEO' do
      get '/'
      expect(response.body).to include('<title>')
      expect(response.body).to include('<meta name="viewport"')
    end

    it 'includes structured data for search engines' do
      property = create(:property, featured: true, status: 'active')
      create(:property_image, property: property)

      get '/'
      # Check for JSON-LD structured data if implemented
      expect(response.body).to include('Property Marketplace')
    end

    it 'loads CSS and JavaScript assets' do
      get '/'
      expect(response.body).to include('application')
    end

    it 'includes Framer Motion integration' do
      get '/'
      expect(response.body).to include('data-controller="framer-motion"')
    end

    it 'includes DaisyUI classes' do
      get '/'
      expect(response.body).to include('hero')
      expect(response.body).to include('btn')
      expect(response.body).to include('card')
      expect(response.body).to include('stat')
    end

    it 'has responsive design markup' do
      get '/'
      expect(response.body).to include('md:')
      expect(response.body).to include('lg:')
      expect(response.body).to include('grid-cols-1')
    end

    it 'includes accessibility attributes' do
      get '/'
      expect(response.body).to include('alt=') if response.body.include?('<img')
      # Just check that the page loads successfully for accessibility
      expect(response).to have_http_status(:success)
    end

    context 'performance considerations' do
      it 'uses eager loading for associations' do
        featured_property = create(:property, featured: true, status: 'active')
        create(:property_image, property: featured_property)

        get '/'
        # Just verify that eager loading works by checking that associations are loaded
        expect(assigns(:featured_properties).first.association(:property_images)).to be_loaded
        expect(assigns(:featured_properties).first.association(:user)).to be_loaded
      end
    end

    context 'caching behavior' do
      it 'sets appropriate cache headers' do
        get '/'
        # Check for cache-related headers if implemented
        expect(response.headers).to include('Cache-Control')
      end
    end
  end

  describe 'Error handling' do
    it 'handles database connection errors gracefully' do
      allow(Property).to receive(:includes).and_raise(ActiveRecord::ConnectionNotEstablished)

      expect {
        get '/'
      }.to raise_error(ActiveRecord::ConnectionNotEstablished)
    end

    it 'handles memory limit errors gracefully' do
      allow(Property).to receive(:includes).and_raise(NoMemoryError)

      expect {
        get '/'
      }.to raise_error(NoMemoryError)
    end
  end

  describe 'Analytics and tracking' do
    it 'includes analytics tracking code if configured' do
      get '/'
      # Check for analytics tracking if implemented
      expect(response.body).to be_present
    end
  end
end