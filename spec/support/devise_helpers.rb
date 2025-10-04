module DeviseHelpers
  def sign_in_user(user = nil)
    user ||= create(:user)
    sign_in user
    user
  end

  def sign_out_user
    sign_out :user
  end
end

RSpec.configure do |config|
  config.include DeviseHelpers, type: :controller
  config.include DeviseHelpers, type: :request
end
