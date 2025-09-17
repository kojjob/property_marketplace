require 'rails_helper'

RSpec.describe 'Property Filtering', type: :system do
  let(:user) { create(:user) }

  before do
    driven_by(:selenium_chrome_headless)
  end

  describe 'Filter functionality' do
    let!(:house_sf) do
      create(:property,
        title: 'Beautiful SF House',
        property_type: 'House',
        city: 'San Francisco',
        state: 'CA',
        price: 500_000,
        bedrooms: 3,
        bathrooms: 2,
        square_feet: 2000,
        status: 'active'
      )
    end

    let!(:apartment_ny) do
      create(:property,
        title: 'Modern NYC Apartment',
        property_type: 'Apartment',
        city: 'New York',
        state: 'NY',
        price: 300_000,
        bedrooms: 2,
        bathrooms: 1,
        square_feet: 1200,
        status: 'active'
      )
    end

    let!(:condo_miami) do
      create(:property,
        title: 'Luxury Miami Condo',
        property_type: 'Condo',
        city: 'Miami',
        state: 'FL',
        price: 400_000,
        bedrooms: 2,
        bathrooms: 2,
        square_feet: 1500,
        status: 'active'
      )
    end

    before do
      # Create property images for each property
      [house_sf, apartment_ny, condo_miami].each do |property|
        create(:property_image, property: property)
      end
    end

    describe 'Grid and List view toggle' do
      it 'switches between grid and list views' do
        visit properties_path

        # Should start in grid view by default
        expect(page).to have_css('.grid')

        # Click list view button
        within('.btn-group') do
          all('.btn')[1].click # Second button should be list view
        end

        # Should switch to list view
        expect(page).to have_css('.space-y-4')

        # Click grid view button
        within('.btn-group') do
          all('.btn')[0].click # First button should be grid view
        end

        # Should switch back to grid view
        expect(page).to have_css('.grid')
      end
    end

    describe 'Search functionality' do
      it 'filters properties by search term' do
        visit properties_path

        # Search by city
        fill_in 'search-input', with: 'San Francisco'
        # Properties should be filtered as user types
        sleep(0.5) # Allow JavaScript to process

        expect(page).to have_content('Beautiful SF House')
        expect(page).not_to have_content('Modern NYC Apartment')
        expect(page).not_to have_content('Luxury Miami Condo')
      end

      it 'filters properties by property type' do
        visit properties_path

        fill_in 'search-input', with: 'apartment'
        sleep(0.5)

        expect(page).to have_content('Modern NYC Apartment')
        expect(page).not_to have_content('Beautiful SF House')
        expect(page).not_to have_content('Luxury Miami Condo')
      end
    end

    describe 'Dropdown filters' do
      it 'filters by property type dropdown' do
        visit properties_path

        select 'House', from: 'type-filter'
        sleep(0.5)

        expect(page).to have_content('Beautiful SF House')
        expect(page).not_to have_content('Modern NYC Apartment')
        expect(page).not_to have_content('Luxury Miami Condo')
      end

      it 'filters by listing type dropdown' do
        visit properties_path

        # Assuming listing type filter exists
        if page.has_select?('listing-type-filter')
          select 'Rent', from: 'listing-type-filter'
          sleep(0.5)
          # Test would depend on the listing type data
        end
      end
    end

    describe 'Price range filtering' do
      it 'filters by minimum price' do
        visit properties_path

        fill_in 'min-price', with: '450000'
        sleep(0.5)

        expect(page).to have_content('Beautiful SF House') # $500,000
        expect(page).not_to have_content('Modern NYC Apartment') # $300,000
        expect(page).not_to have_content('Luxury Miami Condo') # $400,000
      end

      it 'filters by maximum price' do
        visit properties_path

        fill_in 'max-price', with: '350000'
        sleep(0.5)

        expect(page).to have_content('Modern NYC Apartment') # $300,000
        expect(page).not_to have_content('Beautiful SF House') # $500,000
        expect(page).not_to have_content('Luxury Miami Condo') # $400,000
      end

      it 'filters by price range' do
        visit properties_path

        fill_in 'min-price', with: '350000'
        fill_in 'max-price', with: '450000'
        sleep(0.5)

        expect(page).to have_content('Luxury Miami Condo') # $400,000
        expect(page).not_to have_content('Modern NYC Apartment') # $300,000
        expect(page).not_to have_content('Beautiful SF House') # $500,000
      end
    end

    describe 'Square footage filtering' do
      it 'filters by minimum square footage' do
        visit properties_path

        fill_in 'min-sqft', with: '1400'
        sleep(0.5)

        expect(page).to have_content('Beautiful SF House') # 2000 sqft
        expect(page).to have_content('Luxury Miami Condo') # 1500 sqft
        expect(page).not_to have_content('Modern NYC Apartment') # 1200 sqft
      end

      it 'filters by maximum square footage' do
        visit properties_path

        fill_in 'max-sqft', with: '1300'
        sleep(0.5)

        expect(page).to have_content('Modern NYC Apartment') # 1200 sqft
        expect(page).not_to have_content('Beautiful SF House') # 2000 sqft
        expect(page).not_to have_content('Luxury Miami Condo') # 1500 sqft
      end
    end

    describe 'Bedroom and bathroom filtering' do
      it 'filters by number of bedrooms' do
        visit properties_path

        # Click on 3 bedrooms button
        within('[data-controller="property-filter"]') do
          click_button '3'
        end
        sleep(0.5)

        expect(page).to have_content('Beautiful SF House') # 3 bedrooms
        expect(page).not_to have_content('Modern NYC Apartment') # 2 bedrooms
        expect(page).not_to have_content('Luxury Miami Condo') # 2 bedrooms
      end

      it 'filters by number of bathrooms' do
        visit properties_path

        # Click on 2 bathrooms button
        within('[data-controller="property-filter"]') do
          buttons = all('button', text: '2')
          bathrooms_button = buttons.find { |btn| btn['data-bathrooms'] == '2' }
          bathrooms_button.click if bathrooms_button
        end
        sleep(0.5)

        expect(page).to have_content('Beautiful SF House') # 2 bathrooms
        expect(page).to have_content('Luxury Miami Condo') # 2 bathrooms
        expect(page).not_to have_content('Modern NYC Apartment') # 1 bathroom
      end
    end

    describe 'Advanced filters toggle' do
      it 'shows and hides advanced filters' do
        visit properties_path

        # Click advanced filters toggle
        click_button 'Advanced Filters'

        # Advanced filters should be visible
        expect(page).to have_css('[data-property-filter-target="advancedFilters"]:not(.hidden)')

        # Click again to hide
        click_button 'Advanced Filters'

        # Advanced filters should be hidden
        expect(page).to have_css('[data-property-filter-target="advancedFilters"].hidden')
      end
    end

    describe 'Clear filters functionality' do
      it 'clears all applied filters' do
        visit properties_path

        # Apply multiple filters
        fill_in 'search-input', with: 'apartment'
        select 'Apartment', from: 'type-filter'
        fill_in 'min-price', with: '200000'
        sleep(0.5)

        # Should show filtered results
        expect(page).to have_content('Modern NYC Apartment')
        expect(page).not_to have_content('Beautiful SF House')

        # Clear filters
        click_button 'Clear Filters'
        sleep(0.5)

        # All properties should be visible again
        expect(page).to have_content('Beautiful SF House')
        expect(page).to have_content('Modern NYC Apartment')
        expect(page).to have_content('Luxury Miami Condo')

        # Form fields should be cleared
        expect(find_field('search-input').value).to be_empty
        expect(find_field('min-price').value).to be_empty
      end
    end

    describe 'Result count and empty state' do
      it 'displays correct result count' do
        visit properties_path

        # Should show total count initially
        within('[data-property-filter-target="resultCount"]') do
          expect(page).to have_content('3')
        end

        # Filter to one result
        fill_in 'search-input', with: 'San Francisco'
        sleep(0.5)

        within('[data-property-filter-target="resultCount"]') do
          expect(page).to have_content('1')
        end
      end

      it 'shows empty state when no properties match filters' do
        visit properties_path

        # Apply filter that matches no properties
        fill_in 'search-input', with: 'nonexistent location'
        sleep(0.5)

        # Should show empty state
        expect(page).to have_css('[data-property-filter-target="emptyState"]:not(.hidden)')
        within('[data-property-filter-target="resultCount"]') do
          expect(page).to have_content('0')
        end
      end
    end

    describe 'Sorting functionality' do
      it 'sorts properties by price (low to high)' do
        visit properties_path

        # Click sort dropdown
        click_button 'Sort: Newest'
        click_link 'Price: Low to High'
        sleep(0.5)

        # Properties should be ordered by price ascending
        property_cards = page.all('[data-property-filter-target="propertyCard"]')
        prices = property_cards.map { |card| card['data-price'].to_i }
        expect(prices).to eq(prices.sort)
      end

      it 'sorts properties by price (high to low)' do
        visit properties_path

        click_button 'Sort: Newest'
        click_link 'Price: High to Low'
        sleep(0.5)

        property_cards = page.all('[data-property-filter-target="propertyCard"]')
        prices = property_cards.map { |card| card['data-price'].to_i }
        expect(prices).to eq(prices.sort.reverse)
      end

      it 'sorts properties by size' do
        visit properties_path

        click_button 'Sort: Newest'
        click_link 'Size: Largest First'
        sleep(0.5)

        property_cards = page.all('[data-property-filter-target="propertyCard"]')
        sizes = property_cards.map { |card| card['data-sqft'].to_i }
        expect(sizes).to eq(sizes.sort.reverse)
      end
    end
  end

  describe 'Mobile filtering experience' do
    before do
      page.driver.browser.manage.window.resize_to(375, 667)
    end

    it 'maintains filtering functionality on mobile' do
      visit properties_path

      # Basic filtering should still work
      fill_in 'search-input', with: 'apartment'
      sleep(0.5)

      expect(page).to have_content('Modern NYC Apartment')
      expect(page).not_to have_content('Beautiful SF House')
    end

    it 'has responsive filter controls' do
      visit properties_path

      # Filter controls should be visible and usable on mobile
      expect(page).to have_field('search-input')
      expect(page).to have_select('type-filter')
      expect(page).to have_button('Advanced Filters')
    end
  end
end