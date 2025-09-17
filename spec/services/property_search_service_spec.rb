require 'rails_helper'

RSpec.describe PropertySearchService do
  let(:service) { described_class.new(params) }

  let!(:property1) do
    create(:property,
      title: 'Luxury Downtown Penthouse',
      description: 'Amazing views of the city skyline',
      city: 'New York',
      state: 'NY',
      price: 1500000,
      bedrooms: 3,
      bathrooms: 2.5,
      property_type: 'Condo',
      latitude: 40.7128,
      longitude: -74.0060,
      status: 'active'
    )
  end

  let!(:property2) do
    create(:property,
      title: 'Suburban Family Home',
      description: 'Great schools and quiet neighborhood',
      city: 'Los Angeles',
      state: 'CA',
      price: 850000,
      bedrooms: 4,
      bathrooms: 3,
      property_type: 'House',
      latitude: 34.0522,
      longitude: -118.2437,
      status: 'active'
    )
  end

  let!(:property3) do
    create(:property,
      title: 'Beach Front Villa',
      description: 'Steps from the ocean',
      city: 'Miami',
      state: 'FL',
      price: 2000000,
      bedrooms: 5,
      bathrooms: 4,
      property_type: 'House',
      latitude: 25.7617,
      longitude: -80.1918,
      status: 'active'
    )
  end

  let!(:inactive_property) do
    create(:property,
      title: 'Sold Property',
      status: 'sold'
    )
  end

  describe '#call' do
    context 'with text search' do
      let(:params) { { query: 'downtown' } }

      it 'returns properties matching the query' do
        result = service.call
        expect(result).to be_success
        expect(result.data[:properties]).to include(property1)
        expect(result.data[:properties]).not_to include(property2, property3)
      end

      it 'excludes inactive properties' do
        result = service.call
        expect(result.data[:properties]).not_to include(inactive_property)
      end

      it 'includes search metadata' do
        result = service.call
        expect(result.data[:total_count]).to eq(1)
        expect(result.data[:page]).to eq(1)
        expect(result.data[:per_page]).to eq(20)
      end
    end

    context 'with location search' do
      let(:params) do
        {
          location: 'New York, NY',
          radius: 50
        }
      end

      it 'returns properties near the location' do
        result = service.call
        expect(result).to be_success
        expect(result.data[:properties]).to include(property1)
        expect(result.data[:properties]).not_to include(property2, property3)
      end

      it 'includes distance in results' do
        result = service.call
        properties = result.data[:properties]
        expect(properties.first.distance).to be_present
        expect(properties.first.distance).to be < 50
      end
    end

    context 'with coordinate-based location search' do
      let(:params) do
        {
          latitude: 40.7128,
          longitude: -74.0060,
          radius: 100
        }
      end

      it 'returns properties near the coordinates' do
        result = service.call
        expect(result).to be_success
        expect(result.data[:properties]).to include(property1)
      end
    end

    context 'with filters' do
      let(:params) do
        {
          min_price: 800000,
          max_price: 1600000,
          bedrooms: 3,
          property_type: ['Condo', 'House']
        }
      end

      it 'applies all filters correctly' do
        result = service.call
        expect(result).to be_success
        expect(result.data[:properties]).to include(property1, property2)
        expect(result.data[:properties]).not_to include(property3)
      end
    end

    context 'with combined search and filters' do
      let(:params) do
        {
          query: 'family',
          min_price: 500000,
          max_price: 1000000,
          bedrooms: 4
        }
      end

      it 'combines text search with filters' do
        result = service.call
        expect(result).to be_success
        expect(result.data[:properties]).to include(property2)
        expect(result.data[:properties]).not_to include(property1, property3)
      end
    end

    context 'with sorting' do
      let(:params) { { sort_by: 'price_asc' } }

      it 'sorts by price ascending' do
        result = service.call
        properties = result.data[:properties]
        expect(properties.first).to eq(property2)
        expect(properties.last).to eq(property3)
      end

      context 'with price descending' do
        let(:params) { { sort_by: 'price_desc' } }

        it 'sorts by price descending' do
          result = service.call
          properties = result.data[:properties]
          expect(properties.first).to eq(property3)
          expect(properties.second).to eq(property1)
        end
      end

      context 'with newest first' do
        let(:params) { { sort_by: 'newest' } }

        it 'sorts by created_at descending' do
          result = service.call
          properties = result.data[:properties]
          expect(properties.first.created_at).to be >= properties.last.created_at
        end
      end
    end

    context 'with pagination' do
      let(:params) { { page: 2, per_page: 1 } }

      before do
        # Ensure consistent ordering
        Property.update_all(created_at: 1.day.ago)
        property1.update(created_at: 3.days.ago)
        property2.update(created_at: 2.days.ago)
        property3.update(created_at: 1.day.ago)
      end

      it 'returns paginated results' do
        result = service.call
        expect(result.data[:properties].count).to eq(1)
        expect(result.data[:page]).to eq(2)
      end

      it 'includes pagination metadata' do
        result = service.call
        expect(result.data[:total_pages]).to eq(3)
        expect(result.data[:has_next_page]).to be true
        expect(result.data[:has_prev_page]).to be true
      end
    end

    context 'with bounds search (map viewport)' do
      let(:params) do
        {
          bounds: {
            north: 41.0,
            south: 40.0,
            east: -73.0,
            west: -75.0
          }
        }
      end

      it 'returns properties within bounds' do
        result = service.call
        expect(result).to be_success
        expect(result.data[:properties]).to include(property1)
        expect(result.data[:properties]).not_to include(property2, property3)
      end
    end

    context 'with saved search' do
      let(:user) { create(:user) }
      let(:params) do
        {
          query: 'downtown',
          min_price: 1000000,
          save_search: true,
          user: user
        }
      end

      it 'saves the search criteria' do
        expect { service.call }.to change { SavedSearch.count }.by(1)
      end

      it 'associates the search with the user' do
        service.call
        saved_search = SavedSearch.last
        expect(saved_search.user).to eq(user)
        expect(saved_search.criteria['query']).to eq('downtown')
        expect(saved_search.criteria['min_price']).to eq(1000000)
      end
    end

    context 'with invalid parameters' do
      let(:params) { { min_price: 'invalid' } }

      it 'returns validation error' do
        result = service.call
        expect(result).to be_failure
        expect(result.errors).to include('Invalid price format')
      end
    end

    context 'with empty results' do
      let(:params) { { query: 'nonexistent property' } }

      it 'returns empty array with success' do
        result = service.call
        expect(result).to be_success
        expect(result.data[:properties]).to be_empty
        expect(result.data[:total_count]).to eq(0)
      end

      it 'includes search suggestions' do
        result = service.call
        expect(result.data[:suggestions]).to be_present
        expect(result.data[:suggestions]).to include('Try broadening your search criteria')
      end
    end

    context 'with caching' do
      let(:params) { { query: 'downtown', use_cache: true } }

      it 'caches search results' do
        # First call should execute query
        expect(Property).to receive(:search_by_text).and_call_original
        service.call

        # Second call with same params should use cache
        service2 = described_class.new(params)
        expect(Property).not_to receive(:search_by_text)
        result = service2.call
        expect(result).to be_success
      end

      it 'expires cache after TTL' do
        service.call

        # Simulate cache expiration
        Rails.cache.delete(service.send(:cache_key))

        service2 = described_class.new(params)
        expect(Property).to receive(:search_by_text).and_call_original
        service2.call
      end
    end

    context 'with faceted search' do
      let(:params) { { include_facets: true } }

      it 'includes facet counts' do
        result = service.call
        facets = result.data[:facets]

        expect(facets[:property_types]).to include(
          'Condo' => 1,
          'House' => 2
        )

        expect(facets[:price_ranges]).to include(
          '0-500000' => 0,
          '500000-1000000' => 1,
          '1000000-2000000' => 1,
          '2000000+' => 1
        )

        expect(facets[:bedroom_counts]).to include(
          '1' => 0,
          '2' => 0,
          '3' => 1,
          '4' => 1,
          '5+' => 1
        )
      end
    end

    context 'performance considerations' do
      it 'uses includes to avoid N+1 queries' do
        params = { query: 'house' }

        expect {
          result = service.call
          # Access associated data
          result.data[:properties].each do |property|
            property.user.email if property.user
            property.property_images.count
          end
        }.not_to exceed_query_limit(5)
      end

      it 'limits results to prevent memory issues' do
        100.times { create(:property, status: 'active') }

        result = service.call
        expect(result.data[:properties].count).to be <= 100
      end
    end
  end

  describe '#suggestions' do
    let(:params) { { query: 'lux' } }

    it 'provides autocomplete suggestions' do
      suggestions = service.suggestions
      expect(suggestions).to include('luxury')
      expect(suggestions).to include('Luxury Downtown Penthouse')
    end

    it 'limits number of suggestions' do
      suggestions = service.suggestions
      expect(suggestions.count).to be <= 10
    end
  end

  describe '#related_properties' do
    let(:params) { { property_id: property1.id } }

    it 'finds similar properties' do
      related = service.related_properties
      expect(related).not_to include(property1)
      expect(related.count).to be <= 6
    end

    it 'prioritizes properties in same area' do
      nearby_property = create(:property,
        city: 'New York',
        state: 'NY',
        latitude: 40.7200,
        longitude: -74.0100,
        status: 'active'
      )

      related = service.related_properties
      expect(related.first).to eq(nearby_property)
    end
  end
end