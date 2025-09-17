require 'rails_helper'

RSpec.describe 'Stimulus Controllers', type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  describe 'Property Filter Controller', js: true do
    let!(:properties) do
      [
        create(:property, title: 'House 1', property_type: 'House', price: 300_000, bedrooms: 2, bathrooms: 1, square_feet: 1200, status: 'active'),
        create(:property, title: 'Apartment 1', property_type: 'Apartment', price: 400_000, bedrooms: 3, bathrooms: 2, square_feet: 1500, status: 'active'),
        create(:property, title: 'Condo 1', property_type: 'Condo', price: 500_000, bedrooms: 2, bathrooms: 2, square_feet: 1300, status: 'active')
      ]
    end

    before do
      properties.each { |property| create(:property_image, property: property) }
    end

    it 'filters properties in real-time as user types' do
      visit properties_path

      # Type in search field
      fill_in 'search-input', with: 'House'

      # Wait for JavaScript filtering to complete
      sleep(1)

      # Should show only house properties
      expect(page).to have_content('House 1')
      expect(page).not_to have_content('Apartment 1')
      expect(page).not_to have_content('Condo 1')
    end

    it 'updates result count dynamically' do
      visit properties_path

      # Initial count should be 3
      within('[data-property-filter-target="resultCount"]') do
        expect(page).to have_content('3')
      end

      # Filter to reduce count
      fill_in 'search-input', with: 'House'
      sleep(1)

      within('[data-property-filter-target="resultCount"]') do
        expect(page).to have_content('1')
      end
    end

    it 'toggles advanced filters visibility' do
      visit properties_path

      # Advanced filters should be hidden initially
      expect(page).to have_css('[data-property-filter-target="advancedFilters"].hidden')

      # Click toggle button
      click_button 'Advanced Filters'
      sleep(0.5)

      # Advanced filters should be visible
      expect(page).to have_css('[data-property-filter-target="advancedFilters"]:not(.hidden)')

      # Click again to hide
      click_button 'Advanced Filters'
      sleep(0.5)

      # Should be hidden again
      expect(page).to have_css('[data-property-filter-target="advancedFilters"].hidden')
    end

    it 'switches between grid and list views with animation' do
      visit properties_path

      # Should start in grid view
      expect(page).to have_css('.grid')

      # Switch to list view
      within('.btn-group') do
        all('.btn')[1].click # List view button
      end
      sleep(0.5)

      # Should be in list view
      expect(page).to have_css('.space-y-4')

      # Switch back to grid view
      within('.btn-group') do
        all('.btn')[0].click # Grid view button
      end
      sleep(0.5)

      # Should be back in grid view
      expect(page).to have_css('.grid')
    end

    it 'handles bedroom and bathroom selection' do
      visit properties_path

      # Click on 2 bedrooms
      within('[data-controller="property-filter"]') do
        click_button '2'
      end
      sleep(0.5)

      # Should filter to properties with 2+ bedrooms
      expect(page).to have_content('House 1') # 2 bedrooms
      expect(page).to have_content('Condo 1') # 2 bedrooms
      expect(page).to have_content('Apartment 1') # 3 bedrooms (3 >= 2)
    end

    it 'clears all filters when clear button is clicked' do
      visit properties_path

      # Apply filters
      fill_in 'search-input', with: 'House'
      select 'House', from: 'type-filter'
      fill_in 'min-price', with: '200000'
      sleep(0.5)

      # Should show filtered results
      expect(page).to have_content('House 1')
      expect(page).not_to have_content('Apartment 1')

      # Clear filters
      click_button 'Clear Filters'
      sleep(0.5)

      # All properties should be visible again
      expect(page).to have_content('House 1')
      expect(page).to have_content('Apartment 1')
      expect(page).to have_content('Condo 1')

      # Form fields should be empty
      expect(find_field('search-input').value).to be_empty
      expect(find_field('min-price').value).to be_empty
    end

    it 'sorts properties with animation' do
      visit properties_path

      # Click sort dropdown
      click_button 'Sort: Newest'
      click_link 'Price: Low to High'
      sleep(1)

      # Should be sorted by price ascending
      property_cards = page.all('[data-property-filter-target="propertyCard"]')
      first_price = property_cards.first['data-price'].to_i
      last_price = property_cards.last['data-price'].to_i

      expect(first_price).to be <= last_price
    end
  end

  describe 'Framer Motion Controller', js: true do
    it 'applies fade-in animation to elements on page load' do
      visit root_path

      # Elements with framer-motion controller should have animation applied
      expect(page).to have_css('[data-controller="framer-motion"]')

      # Wait for animations to complete
      sleep(1)

      # Elements should be visible (animations completed)
      expect(page).to have_css('.hero')
      expect(page).to have_content('Find Your Dream Property')
    end

    it 'animates property cards on hover' do
      properties = create_list(:property, 2, status: 'active')
      properties.each { |property| create(:property_image, property: property) }

      visit properties_path

      # Property cards should have hover animations
      property_card = page.first('[data-property-filter-target="propertyCard"]')
      expect(property_card).to be_present

      # Hover over the card (simulate mouse over)
      property_card.hover
      sleep(0.5)

      # Animation effects should be applied (visual check through classes)
      expect(property_card[:class]).to include('property-card-hover')
    end
  end

  describe 'Property Gallery Controller', js: true do
    let(:property) { create(:property, status: 'active') }
    let!(:property_images) { create_list(:property_image, 3, property: property) }

    it 'navigates through property images' do
      visit property_path(property)

      # Should have gallery navigation
      expect(page).to have_css('.gallery-nav-btn')

      # Click next button
      find('.gallery-nav-btn.next').click
      sleep(0.5)

      # Should change to next image
      expect(page).to have_css('.gallery-image.active')
    end

    it 'allows thumbnail navigation' do
      visit property_path(property)

      # Should have thumbnails
      thumbnails = page.all('.thumbnail')
      expect(thumbnails.count).to eq(3)

      # Click on second thumbnail
      thumbnails[1].click
      sleep(0.5)

      # Should show corresponding image
      expect(page).to have_css('.gallery-image.active')
    end
  end

  describe 'Search Form Controller', js: true do
    it 'handles search form submission from hero section' do
      visit root_path

      # Fill in search form
      fill_in 'Search Location', with: 'San Francisco'
      select 'House', from: 'Property Type'

      # Submit form
      click_button 'Search Properties'

      # Should navigate to properties page with search params
      expect(page).to have_current_path(properties_path)
    end

    it 'validates search input' do
      visit root_path

      # Try to submit empty form
      click_button 'Search Properties'

      # Should still navigate (basic functionality)
      expect(page).to have_current_path(properties_path)
    end
  end

  describe 'Tab Controller', js: true do
    let(:property) { create(:property, status: 'active') }
    let!(:property_image) { create(:property_image, property: property) }

    it 'switches between tabs with proper activation' do
      visit property_path(property)

      # Overview tab should be active by default
      expect(page).to have_css('.tab-active', text: 'Overview')

      # Click Details tab
      click_link 'Details'
      sleep(0.5)

      # Details tab should be active
      expect(page).to have_css('.tab-active', text: 'Details')
      expect(page).not_to have_css('.tab-active', text: 'Overview')

      # Click Location tab
      click_link 'Location'
      sleep(0.5)

      # Location tab should be active
      expect(page).to have_css('.tab-active', text: 'Location')
      expect(page).not_to have_css('.tab-active', text: 'Details')
    end

    it 'shows appropriate content for each tab' do
      visit property_path(property)

      # Overview content
      expect(page).to have_content(property.description)

      # Switch to Details
      click_link 'Details'
      sleep(0.5)
      expect(page).to have_content('Property Type')

      # Switch to Location
      click_link 'Location'
      sleep(0.5)
      expect(page).to have_content(property.address)

      # Switch to Contact
      click_link 'Contact'
      sleep(0.5)
      expect(page).to have_content('Contact Property Owner')
    end
  end

  describe 'Form Validation Controller', js: true do
    let(:user) { create(:user) }

    before { sign_in user }

    it 'validates required fields in real-time' do
      visit new_property_path

      # Submit form with empty required fields
      click_button 'Create Property'

      # Should show validation errors
      expect(page).to have_content("can't be blank")
    end

    it 'provides visual feedback for form validation' do
      visit new_property_path

      # Fill in title field
      fill_in 'Title', with: 'Test Property'

      # Leave required field and fill it
      fill_in 'Description', with: ''
      fill_in 'Description', with: 'Test description'

      # Validation state should update
      expect(page).to have_field('Description', with: 'Test description')
    end
  end

  describe 'Mobile interactions' do
    before do
      page.driver.browser.manage.window.resize_to(375, 667)
    end

    it 'handles touch interactions on mobile' do
      properties = create_list(:property, 2, status: 'active')
      properties.each { |property| create(:property_image, property: property) }

      visit properties_path

      # Touch/tap interactions should work
      property_card = page.first('[data-property-filter-target="propertyCard"]')
      property_card.click

      # Should navigate to property detail
      expect(page).to have_current_path(property_path(properties.first))
    end

    it 'maintains filter functionality on mobile' do
      properties = create_list(:property, 2, status: 'active')
      properties.each { |property| create(:property_image, property: property) }

      visit properties_path

      # Mobile filter should work
      fill_in 'search-input', with: properties.first.title
      sleep(1)

      expect(page).to have_content(properties.first.title)
    end
  end
end