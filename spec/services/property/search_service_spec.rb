require 'rails_helper'

RSpec.describe Property::SearchService, type: :service do
  let(:user) { create(:user) }
  let!(:apartment_downtown) do
    create(:property,
           property_type: 'Apartment',
           title: 'Modern Downtown Apartment',
           city: 'San Francisco',
           region: 'California',
           price: 3000,
           bedrooms: 2,
           bathrooms: 2,
           square_feet: 1200)
  end

  let!(:house_suburbs) do
    create(:property,
           property_type: 'House',
           title: 'Spacious Suburban House',
           city: 'Oakland',
           region: 'California',
           price: 2500,
           bedrooms: 4,
           bathrooms: 3,
           square_feet: 2000)
  end

  let!(:condo_luxury) do
    create(:property,
           property_type: 'Condo',
           title: 'Luxury Waterfront Condo',
           city: 'San Francisco',
           region: 'California',
           price: 5000,
           bedrooms: 3,
           bathrooms: 2,
           square_feet: 1800)
  end

  describe '#call' do
    context 'without any filters' do
      it 'returns all active properties' do
        result = described_class.new({}).call

        expect(result.success?).to be true
        expect(result.data[:properties].count).to eq(3)
      end
    end

    context 'with city filter' do
      it 'returns properties matching the city' do
        params = { city: 'San Francisco' }
        result = described_class.new(params).call

        expect(result.success?).to be true
        expect(result.data[:properties].count).to eq(2)
        expect(result.data[:properties]).to include(apartment_downtown, condo_luxury)
        expect(result.data[:properties]).not_to include(house_suburbs)
      end
    end

    context 'with property type filter' do
      it 'returns properties matching the type' do
        params = { property_type: 'House' }
        result = described_class.new(params).call

        expect(result.success?).to be true
        expect(result.data[:properties].count).to eq(1)
        expect(result.data[:properties]).to include(house_suburbs)
      end
    end

    context 'with price range filter' do
      it 'returns properties within the price range' do
        params = { min_price: 2000, max_price: 3500 }
        result = described_class.new(params).call

        expect(result.success?).to be true
        expect(result.data[:properties].count).to eq(2)
        expect(result.data[:properties]).to include(apartment_downtown, house_suburbs)
        expect(result.data[:properties]).not_to include(condo_luxury)
      end
    end

    context 'with bedroom filter' do
      it 'returns properties with minimum bedrooms' do
        params = { min_bedrooms: 3 }
        result = described_class.new(params).call

        expect(result.success?).to be true
        expect(result.data[:properties].count).to eq(2)
        expect(result.data[:properties]).to include(house_suburbs, condo_luxury)
        expect(result.data[:properties]).not_to include(apartment_downtown)
      end
    end

    context 'with bathroom filter' do
      it 'returns properties with minimum bathrooms' do
        params = { min_bathrooms: 3 }
        result = described_class.new(params).call

        expect(result.success?).to be true
        expect(result.data[:properties].count).to eq(1)
        expect(result.data[:properties]).to include(house_suburbs)
      end
    end

    context 'with square feet filter' do
      it 'returns properties with minimum square feet' do
        params = { min_square_feet: 1500 }
        result = described_class.new(params).call

        expect(result.success?).to be true
        expect(result.data[:properties].count).to eq(2)
        expect(result.data[:properties]).to include(house_suburbs, condo_luxury)
        expect(result.data[:properties]).not_to include(apartment_downtown)
      end
    end

    context 'with search query' do
      it 'returns properties matching the search query' do
        params = { q: 'Modern Downtown' }
        result = described_class.new(params).call

        expect(result.success?).to be true
        expect(result.data[:properties].count).to eq(1)
        expect(result.data[:properties]).to include(apartment_downtown)
      end
    end

    context 'with multiple filters' do
      it 'returns properties matching all filters' do
        params = {
          city: 'San Francisco',
          property_type: 'Apartment',
          min_price: 2500,
          max_price: 3500
        }
        result = described_class.new(params).call

        expect(result.success?).to be true
        expect(result.data[:properties].count).to eq(1)
        expect(result.data[:properties]).to include(apartment_downtown)
      end
    end

    context 'with sort order' do
      it 'sorts by price ascending' do
        params = { sort: 'price', order: 'asc' }
        result = described_class.new(params).call

        expect(result.success?).to be true
        properties = result.data[:properties]
        expect(properties.first).to eq(house_suburbs)
        expect(properties.last).to eq(condo_luxury)
      end

      it 'sorts by price descending' do
        params = { sort: 'price', order: 'desc' }
        result = described_class.new(params).call

        expect(result.success?).to be true
        properties = result.data[:properties]
        expect(properties.first).to eq(condo_luxury)
        expect(properties.last).to eq(house_suburbs)
      end
    end

    context 'with pagination' do
      it 'returns paginated results' do
        params = { page: 1, per_page: 2 }
        result = described_class.new(params).call

        expect(result.success?).to be true
        expect(result.data[:properties].count).to eq(2)
        expect(result.data[:pagination]).to include(
          current_page: 1,
          per_page: 2,
          total_pages: 2,
          total_count: 3
        )
      end
    end

    context 'with no matching results' do
      it 'returns empty result set' do
        params = { city: 'Nonexistent City' }
        result = described_class.new(params).call

        expect(result.success?).to be true
        expect(result.data[:properties].count).to eq(0)
      end
    end
  end
end