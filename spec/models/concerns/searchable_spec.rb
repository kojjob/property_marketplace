require 'rails_helper'

RSpec.describe 'Searchable', type: :model do
  describe 'Property search functionality' do
    let!(:property1) do
      create(:property,
        title: 'Beautiful Downtown Condo',
        description: 'Luxury condo with amazing views',
        address: '123 Main St',
        city: 'New York',
        state: 'NY',
        zip_code: '10001',
        price: 500000,
        bedrooms: 2,
        bathrooms: 2,
        square_feet: 1200,
        property_type: 'Condo',
        latitude: 40.7128,
        longitude: -74.0060
      )
    end

    let!(:property2) do
      create(:property,
        title: 'Spacious Family House',
        description: 'Perfect home for families with children',
        address: '456 Oak Ave',
        city: 'Los Angeles',
        state: 'CA',
        zip_code: '90001',
        price: 750000,
        bedrooms: 4,
        bathrooms: 3,
        square_feet: 2500,
        property_type: 'House',
        latitude: 34.0522,
        longitude: -118.2437
      )
    end

    let!(:property3) do
      create(:property,
        title: 'Modern Studio Apartment',
        description: 'Cozy studio in the heart of downtown',
        address: '789 Pine St',
        city: 'San Francisco',
        state: 'CA',
        zip_code: '94102',
        price: 300000,
        bedrooms: 0,
        bathrooms: 1,
        square_feet: 600,
        property_type: 'Apartment',
        latitude: 37.7749,
        longitude: -122.4194
      )
    end

    describe '.search_by_text' do
      it 'finds properties by title' do
        results = Property.search_by_text('Downtown')
        expect(results).to include(property1)
        expect(results).to include(property3)  # Also has "downtown" in description
        expect(results).not_to include(property2)
      end

      it 'finds properties by description' do
        results = Property.search_by_text('families')
        expect(results).to include(property2)
        expect(results).not_to include(property1, property3)
      end

      it 'finds properties by city' do
        results = Property.search_by_text('San Francisco')
        expect(results).to include(property3)
        expect(results).not_to include(property1, property2)
      end

      it 'is case insensitive' do
        results = Property.search_by_text('DOWNTOWN')
        expect(results).to include(property1, property3)
      end

      it 'handles partial matches' do
        results = Property.search_by_text('stud')
        expect(results).to include(property3)
      end

      it 'returns empty array for no matches' do
        results = Property.search_by_text('nonexistent')
        expect(results).to be_empty
      end
    end

    describe '.filter_by_price' do
      it 'filters by minimum price' do
        results = Property.filter_by_price(min: 400000)
        expect(results).to include(property1, property2)
        expect(results).not_to include(property3)
      end

      it 'filters by maximum price' do
        results = Property.filter_by_price(max: 600000)
        expect(results).to include(property1, property3)
        expect(results).not_to include(property2)
      end

      it 'filters by price range' do
        results = Property.filter_by_price(min: 300000, max: 600000)
        expect(results).to include(property1, property3)
        expect(results).not_to include(property2)
      end

      it 'returns all properties when no price filters provided' do
        results = Property.filter_by_price({})
        expect(results).to include(property1, property2, property3)
      end
    end

    describe '.filter_by_bedrooms' do
      it 'filters by exact bedroom count' do
        results = Property.filter_by_bedrooms(2)
        expect(results).to include(property1)
        expect(results).not_to include(property2, property3)
      end

      it 'filters by minimum bedrooms' do
        results = Property.filter_by_bedrooms(min: 2)
        expect(results).to include(property1, property2)
        expect(results).not_to include(property3)
      end

      it 'includes studios when filtering for 0 bedrooms' do
        results = Property.filter_by_bedrooms(0)
        expect(results).to include(property3)
        expect(results).not_to include(property1, property2)
      end
    end

    describe '.filter_by_bathrooms' do
      it 'filters by minimum bathrooms' do
        results = Property.filter_by_bathrooms(min: 2)
        expect(results).to include(property1, property2)
        expect(results).not_to include(property3)
      end
    end

    describe '.filter_by_property_type' do
      it 'filters by single property type' do
        results = Property.filter_by_property_type('House')
        expect(results).to include(property2)
        expect(results).not_to include(property1, property3)
      end

      it 'filters by multiple property types' do
        results = Property.filter_by_property_type([ 'Condo', 'Apartment' ])
        expect(results).to include(property1, property3)
        expect(results).not_to include(property2)
      end
    end

    describe '.near_location' do
      it 'finds properties within a specific radius' do
        # Properties near New York (within 50 miles)
        results = Property.near_location(latitude: 40.7128, longitude: -74.0060, radius: 50)
        expect(results).to include(property1)
        expect(results).not_to include(property2, property3)
      end

      it 'finds properties by address string' do
        results = Property.near_location(address: 'New York, NY', radius: 50)
        expect(results).to include(property1)
        expect(results).not_to include(property2, property3)
      end

      it 'orders results by distance' do
        # Search from a point between SF and LA
        results = Property.near_location(
          latitude: 35.5,
          longitude: -119.0,
          radius: 500
        )

        # LA should be closer than SF from this point
        expect(results.first).to eq(property2)
        expect(results.second).to eq(property3)
      end

      it 'returns empty array when no properties within radius' do
        results = Property.near_location(
          latitude: 25.7617,
          longitude: -80.1918,
          radius: 10  # Miami with small radius
        )
        expect(results).to be_empty
      end
    end

    describe '.advanced_search' do
      it 'combines text search with filters' do
        results = Property.advanced_search(
          query: 'downtown',
          filters: {
            min_price: 200000,
            max_price: 600000
          }
        )
        expect(results).to include(property1, property3)
        expect(results).not_to include(property2)
      end

      it 'combines location search with filters' do
        results = Property.advanced_search(
          location: {
            latitude: 37.7749,
            longitude: -122.4194,
            radius: 100
          },
          filters: {
            property_type: 'Apartment'
          }
        )
        expect(results).to include(property3)
        expect(results).not_to include(property1, property2)
      end

      it 'combines all search parameters' do
        results = Property.advanced_search(
          query: 'studio',
          location: {
            address: 'California',
            radius: 500
          },
          filters: {
            max_price: 400000,
            bathrooms: 1
          }
        )
        expect(results).to include(property3)
        expect(results).not_to include(property1, property2)
      end

      it 'paginates results' do
        results = Property.advanced_search(
          filters: {},
          page: 1,
          per_page: 2
        )
        expect(results.count).to eq(2)
      end

      it 'sorts results by different criteria' do
        results = Property.advanced_search(
          filters: {},
          sort_by: 'price_asc'
        )
        expect(results.first).to eq(property3)
        expect(results.last).to eq(property2)

        results = Property.advanced_search(
          filters: {},
          sort_by: 'price_desc'
        )
        expect(results.first).to eq(property2)
        expect(results.last).to eq(property3)
      end
    end

    describe 'search suggestions' do
      it 'provides autocomplete suggestions for locations' do
        suggestions = Property.location_suggestions('San')
        expect(suggestions).to include('San Francisco, CA')
      end

      it 'suggests popular search terms' do
        # Skip popular terms test for now as it's not implemented
        skip 'Popular search terms not yet implemented'

        # Simulate some searches
        Property.record_search_term('luxury condo')
        Property.record_search_term('luxury condo')
        Property.record_search_term('family house')

        popular = Property.popular_search_terms
        expect(popular.first).to include('luxury condo')
      end
    end

    describe 'search result caching' do
      it 'caches frequently used searches' do
        # Skip caching test for now as it's not implemented
        skip 'Caching not yet implemented'

        # First search should hit the database
        expect(Property).to receive(:where).and_call_original
        Property.search_by_text('downtown')

        # Second identical search should use cache
        expect(Property).not_to receive(:where)
        Property.search_by_text('downtown')
      end
    end
  end
end
