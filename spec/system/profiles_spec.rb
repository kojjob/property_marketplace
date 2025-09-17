require 'rails_helper'

RSpec.describe 'Profiles', type: :system do
  let(:user) { create(:user) }
  let(:profile) { user.profile }

  before do
    driven_by(:selenium_chrome_headless)
    sign_in user
  end

  describe 'viewing a profile' do
    before do
      profile.update!(
        first_name: 'John',
        last_name: 'Doe',
        bio: 'Experienced real estate agent',
        role: 'agent',
        company_name: 'ABC Realty',
        position: 'Senior Agent',
        years_experience: 10,
        languages: 'English, Spanish',
        address: '123 Main St',
        city: 'New York',
        state: 'NY',
        country: 'USA',
        website: 'https://johndoe.com',
        phone_number: '+1234567890'
      )
    end

    it 'displays the profile information correctly' do
      visit profile_path(profile)

      expect(page).to have_content('John Doe')
      expect(page).to have_content('Experienced real estate agent')
      expect(page).to have_content('ABC Realty')
      expect(page).to have_content('Senior Agent')
      expect(page).to have_content('10 years of experience')
      expect(page).to have_content('English, Spanish')
      expect(page).to have_content('123 Main St')
      expect(page).to have_content('New York, NY, USA')
      expect(page).to have_content('+1234567890')
      expect(page).to have_link('johndoe.com', href: 'https://johndoe.com')
    end

    it 'shows edit button for own profile' do
      visit profile_path(profile)
      expect(page).to have_link('Edit Profile', href: edit_profile_path(profile))
    end

    it 'does not show edit button for other profiles' do
      other_user = create(:user)
      visit profile_path(other_user.profile)
      expect(page).to_not have_link('Edit Profile')
    end

    it 'displays role badge correctly' do
      visit profile_path(profile)
      expect(page).to have_content('Agent')
    end

    it 'shows statistics section' do
      visit profile_path(profile)
      expect(page).to have_content('Statistics')
      expect(page).to have_content('Properties Listed')
      expect(page).to have_content('Reviews Received')
    end
  end

  describe 'editing a profile' do
    it 'allows user to edit their profile' do
      visit edit_profile_path(profile)

      expect(page).to have_field('First name', with: profile.first_name)
      expect(page).to have_field('Last name', with: profile.last_name)
      expect(page).to have_field('Phone number', with: profile.phone_number)

      fill_in 'First name', with: 'Updated'
      fill_in 'Last name', with: 'Name'
      fill_in 'Bio', with: 'Updated bio content'
      fill_in 'Company name', with: 'New Company LLC'
      fill_in 'Position', with: 'Lead Agent'
      fill_in 'Years of experience', with: '15'
      fill_in 'Languages', with: 'English, Spanish, French'
      fill_in 'Address', with: '456 New Street'
      fill_in 'City', with: 'Boston'
      fill_in 'State', with: 'MA'
      fill_in 'Country', with: 'USA'
      fill_in 'Website', with: 'https://updatedsite.com'

      click_button 'Update Profile'

      expect(page).to have_current_path(profile_path(profile))
      expect(page).to have_content('Profile was successfully updated.')
      expect(page).to have_content('Updated Name')
      expect(page).to have_content('Updated bio content')
      expect(page).to have_content('New Company LLC')
      expect(page).to have_content('Lead Agent')
      expect(page).to have_content('15 years of experience')
      expect(page).to have_content('English, Spanish, French')
      expect(page).to have_content('456 New Street')
      expect(page).to have_content('Boston, MA, USA')
      expect(page).to have_link('updatedsite.com')
    end

    it 'shows validation errors for invalid input' do
      visit edit_profile_path(profile)

      fill_in 'First name', with: ''
      fill_in 'Last name', with: ''
      fill_in 'Phone number', with: 'invalid-phone'

      click_button 'Update Profile'

      expect(page).to have_content("First name can't be blank")
      expect(page).to have_content("Last name can't be blank")
      expect(page).to have_content('Phone number must be a valid phone number')
    end

    it 'allows user to select different roles' do
      visit edit_profile_path(profile)

      select 'Landlord', from: 'Role'
      click_button 'Update Profile'

      expect(page).to have_content('Profile was successfully updated.')
      visit profile_path(profile)
      expect(page).to have_content('Landlord')
    end

    it 'has properly organized form sections' do
      visit edit_profile_path(profile)

      expect(page).to have_content('Basic Information')
      expect(page).to have_content('Professional Information')
      expect(page).to have_content('Address Information')
      expect(page).to have_content('Social Media Links')
      expect(page).to have_content('Profile Picture')
    end

    it 'includes social media URL fields' do
      visit edit_profile_path(profile)

      fill_in 'Facebook URL', with: 'https://facebook.com/johndoe'
      fill_in 'Twitter URL', with: 'https://twitter.com/johndoe'
      fill_in 'LinkedIn URL', with: 'https://linkedin.com/in/johndoe'
      fill_in 'Instagram URL', with: 'https://instagram.com/johndoe'

      click_button 'Update Profile'

      expect(page).to have_content('Profile was successfully updated.')
    end

    it 'prevents editing other users profiles' do
      other_user = create(:user)
      visit edit_profile_path(other_user.profile)

      expect(page).to have_current_path(root_path)
      expect(page).to have_content('You can only edit your own profile.')
    end
  end

  describe 'navigation integration' do
    it 'allows access to profile from navigation' do
      visit root_path

      # Desktop navigation
      within('nav') do
        click_link 'My Profile'
      end

      expect(page).to have_current_path(profile_path(profile))
    end

    it 'shows edit link in navigation' do
      visit root_path

      within('nav') do
        expect(page).to have_link('Edit Profile', href: edit_profile_path(profile))
      end
    end
  end

  describe 'responsive design' do
    it 'displays properly on mobile', js: true do
      page.driver.browser.manage.window.resize_to(375, 667) # iPhone 6/7/8 size

      visit profile_path(profile)

      expect(page).to have_content(profile.full_name)
      expect(page).to have_css('.profile-header')
      expect(page).to have_css('.profile-content')
    end

    it 'has working mobile navigation' do
      page.driver.browser.manage.window.resize_to(375, 667)

      visit root_path

      # Click mobile menu button
      find('button[aria-label="Open menu"]').click
      click_link 'My Profile'

      expect(page).to have_current_path(profile_path(profile))
    end
  end

  describe 'profile completion prompts' do
    context 'when profile is incomplete' do
      before do
        profile.update!(bio: nil, company_name: nil)
      end

      it 'shows completion prompts' do
        visit profile_path(profile)
        # This would test for any completion prompts if implemented
        expect(page).to have_link('Edit Profile')
      end
    end
  end

  describe 'avatar functionality' do
    it 'shows default avatar when none uploaded' do
      visit profile_path(profile)
      expect(page).to have_css('img[alt="Profile Avatar"]')
    end

    it 'has avatar upload field in edit form' do
      visit edit_profile_path(profile)
      expect(page).to have_field('Avatar')
    end
  end
end