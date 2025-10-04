require 'rails_helper'

RSpec.describe 'Home Page', type: :system do
  let(:user) { create(:user) }

  before do
    driven_by(:selenium_chrome_headless)
  end

  describe 'Page structure and content' do
    context 'with featured properties' do
      let!(:featured_properties) do
        create_list(:property, 4, featured: true, status: 'active').tap do |properties|
          properties.each { |property| create(:property_image, property: property) }
        end
      end

      it 'displays the hero section with search functionality' do
        visit root_path

        expect(page).to have_css('.hero')
        expect(page).to have_content('Find Your Dream Property')
        expect(page).to have_field('Search Location')
        expect(page).to have_select('Property Type')
        expect(page).to have_button('Search Properties')
      end

      it 'displays the property types section' do
        visit root_path

        expect(page).to have_content('Explore by Property Type')
        expect(page).to have_content('Find the perfect property type that suits your lifestyle')

        # Check for property type cards
        expect(page).to have_content('Houses')
        expect(page).to have_content('Perfect for families and those who want space and privacy')
        expect(page).to have_content('Apartments')
        expect(page).to have_content('Modern living in the heart of the city')
        expect(page).to have_content('Condos')
        expect(page).to have_content('Luxury amenities with low maintenance lifestyle')
        expect(page).to have_content('Commercial')
        expect(page).to have_content('Investment opportunities and business spaces')
      end

      it 'displays the market statistics section' do
        visit root_path

        expect(page).to have_content('Market Performance')
        expect(page).to have_content('Real-time insights into our marketplace success')

        # Check for statistics
        expect(page).to have_content('Total Properties')
        expect(page).to have_content('2,847')
        expect(page).to have_content('Happy Clients')
        expect(page).to have_content('15,892')
        expect(page).to have_content('Avg Property Value')
        expect(page).to have_content('$425K')
        expect(page).to have_content('Avg Sale Time')
        expect(page).to have_content('18 Days')
      end

      it 'displays the cities we serve section' do
        visit root_path

        expect(page).to have_content('Cities We Serve')
        expect(page).to have_content('Discover amazing properties in prime locations')

        # Check for city cards
        cities = [ 'San Francisco', 'New York', 'Miami', 'Austin', 'Seattle', 'Portland' ]
        cities.each do |city|
          expect(page).to have_content(city)
        end
      end

      it 'displays the featured properties section' do
        visit root_path

        expect(page).to have_content('Featured Properties')
        expect(page).to have_content('Discover our handpicked selection of premium properties')

        # Should display the featured properties
        featured_properties.each do |property|
          expect(page).to have_content(property.title)
          expect(page).to have_content("$#{number_with_delimiter(property.price)}")
        end
      end

      it 'displays the why choose us section' do
        visit root_path

        expect(page).to have_content('Why Choose PropertyMarketplace?')
        expect(page).to have_content('Expert Guidance')
        expect(page).to have_content('Verified Listings')
        expect(page).to have_content('Seamless Process')
      end

      it 'displays the call to action section' do
        visit root_path

        expect(page).to have_content('Ready to Find Your Dream Property?')
        expect(page).to have_link('Start Your Search', href: properties_path)
      end
    end

    context 'without featured properties' do
      let!(:recent_properties) do
        create_list(:property, 3, featured: false, status: 'active').tap do |properties|
          properties.each { |property| create(:property_image, property: property) }
        end
      end

      it 'displays recent properties when no featured ones exist' do
        visit root_path

        expect(page).to have_content('Featured Properties')
        recent_properties.each do |property|
          expect(page).to have_content(property.title)
        end
      end
    end

    context 'with no properties' do
      it 'displays empty state appropriately' do
        visit root_path

        expect(page).to have_content('Featured Properties')
        # The page should still load successfully even with no properties
        expect(page).to have_current_path(root_path)
      end
    end
  end

  describe 'Navigation and user interaction' do
    it 'has proper navigation structure' do
      visit root_path

      expect(page).to have_link('PropertyMarketplace')
      expect(page).to have_link('Properties')
      expect(page).to have_link('Sign In')
      expect(page).to have_link('Sign Up')
    end

    context 'when user is signed in' do
      before { sign_in user }

      it 'shows user-specific navigation' do
        visit root_path

        expect(page).to have_content(user.email)
        expect(page).to have_link('Add Property')
        expect(page).to have_button('Sign Out')
      end
    end

    it 'allows navigation to properties page' do
      visit root_path

      click_link 'Properties'
      expect(page).to have_current_path(properties_path)
    end

    it 'allows navigation via call-to-action button' do
      visit root_path

      click_link 'Start Your Search'
      expect(page).to have_current_path(properties_path)
    end
  end

  describe 'Search functionality' do
    it 'has functional search form in hero section' do
      visit root_path

      expect(page).to have_field('Search Location')
      expect(page).to have_select('Property Type')
      expect(page).to have_button('Search Properties')
    end

    it 'redirects to properties page when search is performed' do
      visit root_path

      fill_in 'Search Location', with: 'San Francisco'
      select 'House', from: 'Property Type'
      click_button 'Search Properties'

      expect(page).to have_current_path(properties_path)
    end
  end

  describe 'Responsive design' do
    it 'displays properly on mobile viewport' do
      resize_to_mobile
      visit root_path

      # Check that key elements are still visible on mobile
      expect(page).to have_content('Find Your Dream Property')
      expect(page).to have_content('Featured Properties')
      expect(page).to have_content('Why Choose PropertyMarketplace?')
    end

    it 'displays properly on tablet viewport' do
      resize_to_tablet
      visit root_path

      # Check that the layout adapts properly for tablet
      expect(page).to have_content('Find Your Dream Property')
      expect(page).to have_content('Explore by Property Type')
      expect(page).to have_content('Cities We Serve')
    end
  end

  describe 'Performance and accessibility' do
    it 'loads the page within reasonable time' do
      start_time = Time.current
      visit root_path
      load_time = Time.current - start_time

      expect(load_time).to be < 5.seconds
    end

    it 'has proper accessibility elements' do
      visit root_path

      # Check for proper heading structure
      expect(page).to have_css('h1')
      expect(page).to have_css('h2')

      # Check for alt text on images (when properties have images)
      if page.has_css?('img')
        page.all('img').each do |img|
          expect(img[:alt]).not_to be_empty
        end
      end
    end
  end

  private

  def resize_to_mobile
    page.driver.browser.manage.window.resize_to(375, 667)
  end

  def resize_to_tablet
    page.driver.browser.manage.window.resize_to(768, 1024)
  end

  def number_with_delimiter(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
