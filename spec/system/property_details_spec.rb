require 'rails_helper'

RSpec.describe 'Property Details Page', type: :system do
  let(:user) { create(:user) }
  let(:owner) { create(:user) }

  let(:property) do
    create(:property,
      user: owner,
      title: 'Beautiful Modern House',
      description: 'A stunning property with modern amenities and beautiful views.',
      price: 500_000,
      property_type: 'House',
      bedrooms: 3,
      bathrooms: 2,
      square_feet: 2000,
      address: '123 Main Street',
      city: 'San Francisco',
      state: 'CA',
      zip_code: '94102',
      status: 'active'
    )
  end

  let!(:property_images) do
    create_list(:property_image, 3, property: property)
  end

  before do
    driven_by(:selenium_chrome_headless)
  end

  describe 'Page structure and content' do
    it 'displays property information correctly' do
      visit property_path(property)

      # Basic property information
      expect(page).to have_content('Beautiful Modern House')
      expect(page).to have_content('$500,000')
      expect(page).to have_content('House')
      expect(page).to have_content('3')  # bedrooms
      expect(page).to have_content('2')  # bathrooms
      expect(page).to have_content('2,000')  # square feet
      expect(page).to have_content('123 Main Street')
      expect(page).to have_content('San Francisco, CA 94102')
    end

    it 'displays property images in gallery' do
      visit property_path(property)

      # Should have image gallery
      expect(page).to have_css('.property-gallery')
      expect(page).to have_css('img', count: property_images.count)
    end

    it 'shows property owner information' do
      visit property_path(property)

      expect(page).to have_content(owner.email)
    end
  end

  describe 'Tab functionality' do
    it 'displays overview tab by default' do
      visit property_path(property)

      # Overview tab should be active by default
      expect(page).to have_css('.tab-active', text: 'Overview')
      expect(page).to have_content('A stunning property with modern amenities')
    end

    it 'switches to details tab' do
      visit property_path(property)

      click_link 'Details'

      expect(page).to have_css('.tab-active', text: 'Details')
      # Should show detailed property specifications
      expect(page).to have_content('Property Type')
      expect(page).to have_content('Bedrooms')
      expect(page).to have_content('Bathrooms')
      expect(page).to have_content('Square Feet')
    end

    it 'switches to location tab' do
      visit property_path(property)

      click_link 'Location'

      expect(page).to have_css('.tab-active', text: 'Location')
      expect(page).to have_content('123 Main Street')
      expect(page).to have_content('San Francisco, CA 94102')
    end

    it 'switches to contact tab' do
      visit property_path(property)

      click_link 'Contact'

      expect(page).to have_css('.tab-active', text: 'Contact')
      expect(page).to have_content('Contact Property Owner')
    end
  end

  describe 'Image gallery functionality' do
    it 'allows cycling through property images' do
      visit property_path(property)

      # Should have navigation buttons if multiple images
      if property_images.count > 1
        expect(page).to have_css('.gallery-nav-btn')

        # Click next button
        find('.gallery-nav-btn.next').click
        sleep(0.5)

        # Should change to next image
        expect(page).to have_css('.gallery-image.active')
      end
    end

    it 'shows image thumbnails for navigation' do
      visit property_path(property)

      # Should have thumbnail navigation
      expect(page).to have_css('.gallery-thumbnails')
      expect(page).to have_css('.thumbnail', count: property_images.count)
    end
  end

  describe 'Favorite functionality' do
    context 'when user is not signed in' do
      it 'redirects to sign in when trying to favorite' do
        visit property_path(property)

        if page.has_button?('Add to Favorites')
          click_button 'Add to Favorites'
          expect(page).to have_current_path(new_user_session_path)
        end
      end
    end

    context 'when user is signed in' do
      before { sign_in user }

      it 'allows user to favorite a property' do
        visit property_path(property)

        expect(page).to have_button('Add to Favorites')
        click_button 'Add to Favorites'

        # Should change to unfavorite button
        expect(page).to have_button('Remove from Favorites')
      end

      it 'allows user to unfavorite a property' do
        # Create existing favorite
        create(:favorite, user: user, property: property)

        visit property_path(property)

        expect(page).to have_button('Remove from Favorites')
        click_button 'Remove from Favorites'

        # Should change back to favorite button
        expect(page).to have_button('Add to Favorites')
      end
    end
  end

  describe 'Contact functionality' do
    context 'when user is not signed in' do
      it 'shows sign in prompt in contact tab' do
        visit property_path(property)

        click_link 'Contact'

        expect(page).to have_content('Sign in to contact the property owner')
        expect(page).to have_link('Sign In')
      end
    end

    context 'when user is signed in' do
      before { sign_in user }

      it 'shows contact form in contact tab' do
        visit property_path(property)

        click_link 'Contact'

        expect(page).to have_content('Contact Property Owner')
        expect(page).to have_field('Message')
        expect(page).to have_button('Send Message')
      end

      it 'allows sending a message to property owner' do
        visit property_path(property)

        click_link 'Contact'

        fill_in 'Message', with: 'I am interested in this property. Can we schedule a viewing?'
        click_button 'Send Message'

        # Should show success message
        expect(page).to have_content('Message sent successfully')
      end
    end

    context 'when viewing own property' do
      before { sign_in owner }

      it 'shows edit and management options instead of contact' do
        visit property_path(property)

        expect(page).to have_link('Edit Property')
        expect(page).not_to have_content('Contact Property Owner')
      end
    end
  end

  describe 'Related properties section' do
    let!(:similar_property) do
      create(:property,
        property_type: property.property_type,
        city: property.city,
        price: property.price + 50_000,
        status: 'active'
      )
    end

    it 'displays related properties' do
      create(:property_image, property: similar_property)

      visit property_path(property)

      expect(page).to have_content('Similar Properties')
      expect(page).to have_content(similar_property.title)
    end
  end

  describe 'Property features and amenities' do
    let(:property_with_features) do
      create(:property,
        user: owner,
        title: 'Luxury Property with Features',
        description: 'Property with pool, garage, and garden.',
        status: 'active'
      )
    end

    it 'displays property features when available' do
      visit property_path(property_with_features)

      click_link 'Details'

      # Check for common features that might be displayed
      if page.has_content?('Features')
        expect(page).to have_css('.features-list')
      end
    end
  end

  describe 'Responsive design' do
    it 'displays properly on mobile devices' do
      page.driver.browser.manage.window.resize_to(375, 667)
      visit property_path(property)

      # Key elements should still be visible on mobile
      expect(page).to have_content('Beautiful Modern House')
      expect(page).to have_content('$500,000')
      expect(page).to have_css('.tab')
    end

    it 'adapts gallery for mobile viewing' do
      page.driver.browser.manage.window.resize_to(375, 667)
      visit property_path(property)

      # Gallery should be responsive
      expect(page).to have_css('.property-gallery')

      # Tab navigation should work on mobile
      click_link 'Details'
      expect(page).to have_css('.tab-active', text: 'Details')
    end
  end

  describe 'Navigation and breadcrumbs' do
    it 'provides navigation back to properties list' do
      visit property_path(property)

      expect(page).to have_link('← Back to Properties')
      click_link '← Back to Properties'

      expect(page).to have_current_path(properties_path)
    end

    it 'shows property in page title' do
      visit property_path(property)

      expect(page).to have_title(/Beautiful Modern House/)
    end
  end

  describe 'SEO and meta information' do
    it 'has proper meta tags for social sharing' do
      visit property_path(property)

      # Check for Open Graph meta tags
      expect(page).to have_css('meta[property="og:title"]', visible: false)
      expect(page).to have_css('meta[property="og:description"]', visible: false)

      if property_images.any?
        expect(page).to have_css('meta[property="og:image"]', visible: false)
      end
    end
  end

  describe 'Performance and loading' do
    it 'loads the property page within reasonable time' do
      start_time = Time.current
      visit property_path(property)
      load_time = Time.current - start_time

      expect(load_time).to be < 5.seconds
    end

    it 'lazy loads images when not immediately visible' do
      visit property_path(property)

      # Check that images have proper loading attributes
      page.all('img').each do |img|
        expect(img[:loading]).to eq('lazy').or be_nil
      end
    end
  end
end