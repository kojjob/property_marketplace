require 'rails_helper'

RSpec.describe 'Devise Authentication Test', type: :controller do
  controller(ApplicationController) do
    def index
      render plain: 'success'
    end
  end

  describe 'User model' do
    it 'can create a user' do
      user = create(:user)
      expect(user).to be_valid
      expect(user.email).to be_present
    end

    it 'can check devise configuration' do
      expect(User.devise_modules).to include(:database_authenticatable)
      expect(User.devise_modules).to include(:registerable)
    end
  end

  describe 'sign_in helper' do
    it 'can sign in a user' do
      user = create(:user)
      sign_in(user)
      expect(controller.current_user).to eq(user)
    end

    it 'can sign in a user with profile like ProfilesController' do
      user = create(:user)
      profile = create(:profile, user: user)
      sign_in(user)
      expect(controller.current_user).to eq(user)
      expect(controller.current_user.profile).to eq(profile)
    end
  end
end
