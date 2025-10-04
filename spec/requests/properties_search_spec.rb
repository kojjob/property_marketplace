require 'rails_helper'

RSpec.describe 'Properties Search', type: :request do
  let!(:property1) do
    create(:property,
      title: 'Downtown Apartment',
      city: 'New York',
      state: 'NY',
      price: 500000,
      bedrooms: 2,
      property_type: 'Apartment',
      latitude: 40.7128,
      longitude: -74.0060,
      status: 'active'
    )
  end

  let!(:property2) do
    create(:property,
      title: 'Beach House',
      city: 'Miami',
      state: 'FL',
      price: 750000,
      bedrooms: 3,
      property_type: 'House',
      latitude: 25.7617,
      longitude: -80.1918,
      status: 'active'
    )
  end

  describe 'GET /properties/search' do
    it 'returns successful response' do
      get search_properties_path
      expect(response).to have_http_status(:success)
    end

    it 'renders search form' do
      get search_properties_path
      expect(response.body).to include('Search Properties')
      expect(response.body).to include('Location')
      expect(response.body).to include('Price Range')
      expect(response.body).to include('Property Type')
    end

    context 'with search parameters' do
      it 'performs text search' do
        get search_properties_path, params: { q: 'downtown' }
        expect(response.body).to include(property1.title)
        expect(response.body).not_to include(property2.title)
      end

      it 'filters by price range' do
        get search_properties_path, params: {
          min_price: 400000,
          max_price: 600000
        }
        expect(response.body).to include(property1.title)
        expect(response.body).not_to include(property2.title)
      end

      it 'filters by bedrooms' do
        get search_properties_path, params: { bedrooms: 3 }
        expect(response.body).to include(property2.title)
        expect(response.body).not_to include(property1.title)
      end

      it 'filters by property type' do
        get search_properties_path, params: { property_type: 'House' }
        expect(response.body).to include(property2.title)
        expect(response.body).not_to include(property1.title)
      end

      it 'searches by location' do
        get search_properties_path, params: {
          location: 'New York, NY',
          radius: 50
        }
        expect(response.body).to include(property1.title)
        expect(response.body).not_to include(property2.title)
      end

      it 'searches by coordinates' do
        get search_properties_path, params: {
          lat: 40.7128,
          lng: -74.0060,
          radius: 50
        }
        expect(response.body).to include(property1.title)
        expect(response.body).not_to include(property2.title)
      end

      it 'combines multiple filters' do
        get search_properties_path, params: {
          q: 'apartment',
          min_price: 400000,
          max_price: 600000,
          bedrooms: 2
        }
        expect(response.body).to include(property1.title)
        expect(response.body).not_to include(property2.title)
      end
    end

    context 'with sorting' do
      it 'sorts by price ascending' do
        get search_properties_path, params: { sort: 'price_asc' }

        # Check that property1 appears before property2 in the response
        property1_index = response.body.index(property1.title)
        property2_index = response.body.index(property2.title)
        expect(property1_index).to be < property2_index
      end

      it 'sorts by price descending' do
        get search_properties_path, params: { sort: 'price_desc' }

        property1_index = response.body.index(property1.title)
        property2_index = response.body.index(property2.title)
        expect(property2_index).to be < property1_index
      end

      it 'sorts by newest first' do
        property2.update(created_at: 1.day.ago)
        property1.update(created_at: 2.days.ago)

        get search_properties_path, params: { sort: 'newest' }

        property1_index = response.body.index(property1.title) || Float::INFINITY
        property2_index = response.body.index(property2.title) || Float::INFINITY
        expect(property2_index).to be < property1_index
      end
    end

    context 'with pagination' do
      before do
        5.times do |i|
          create(:property,
            title: "Property #{i + 3}",
            status: 'active'
          )
        end
      end

      it 'paginates results' do
        get search_properties_path, params: { page: 1, per_page: 3 }

        expect(response.body).to include('Page 1')
        expect(response.body.scan(/Property \d+/).count).to be <= 3
      end

      it 'shows next page link when applicable' do
        get search_properties_path, params: { page: 1, per_page: 3 }
        expect(response.body).to include('Next')
      end

      it 'shows previous page link when applicable' do
        get search_properties_path, params: { page: 2, per_page: 3 }
        expect(response.body).to include('Previous')
      end
    end

    context 'with map view' do
      it 'includes map container' do
        get search_properties_path, params: { view: 'map' }
        expect(response.body).to include('data-map')
        expect(response.body).to include('data-properties')
      end

      it 'includes property markers data' do
        get search_properties_path, params: { view: 'map' }
        expect(response.body).to include(property1.latitude.to_s)
        expect(response.body).to include(property1.longitude.to_s)
      end

      it 'searches within map bounds' do
        get search_properties_path, params: {
          bounds: {
            north: 41.0,
            south: 40.0,
            east: -73.0,
            west: -75.0
          }
        }
        expect(response.body).to include(property1.title)
        expect(response.body).not_to include(property2.title)
      end
    end

    context 'with saved searches' do
      let(:user) { create(:user) }

      before { sign_in user }

      it 'saves search when requested' do
        expect {
          get search_properties_path, params: {
            q: 'downtown',
            min_price: 400000,
            save_search: true
          }
        }.to change { SavedSearch.count }.by(1)
      end

      it 'shows save search button for authenticated users' do
        get search_properties_path
        expect(response.body).to include('Save Search')
      end
    end

    context 'with empty results' do
      it 'shows no results message' do
        get search_properties_path, params: { q: 'nonexistent' }
        expect(response.body).to include('No properties found')
      end

      it 'shows search suggestions' do
        get search_properties_path, params: { q: 'nonexistent' }
        expect(response.body).to include('Try adjusting your search criteria')
      end
    end

    context 'with JSON format' do
      it 'returns JSON response' do
        get search_properties_path(format: :json)
        expect(response.content_type).to include('application/json')
      end

      it 'includes properties in JSON' do
        get search_properties_path(format: :json), params: { q: 'downtown' }

        json = JSON.parse(response.body)
        expect(json['properties'].count).to eq(1)
        expect(json['properties'].first['title']).to eq(property1.title)
      end

      it 'includes metadata in JSON' do
        get search_properties_path(format: :json)

        json = JSON.parse(response.body)
        expect(json).to have_key('total_count')
        expect(json).to have_key('page')
        expect(json).to have_key('per_page')
        expect(json).to have_key('facets')
      end

      it 'includes map markers in JSON' do
        get search_properties_path(format: :json), params: { include_markers: true }

        json = JSON.parse(response.body)
        expect(json).to have_key('markers')
        expect(json['markers'].first).to include(
          'lat' => property1.latitude,
          'lng' => property1.longitude,
          'title' => property1.title
        )
      end
    end
  end

  describe 'GET /properties/search/autocomplete' do
    it 'returns autocomplete suggestions' do
      get autocomplete_search_properties_path, params: { q: 'down' }

      json = JSON.parse(response.body)
      expect(json['suggestions']).to include('downtown')
      expect(json['properties']).to include(property1.title)
    end

    it 'limits suggestions count' do
      get autocomplete_search_properties_path, params: { q: 'a' }

      json = JSON.parse(response.body)
      expect(json['suggestions'].count).to be <= 10
    end
  end
end
