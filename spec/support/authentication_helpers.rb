module AuthenticationHelpers
  def sign_in(user)
    session = create(:session, user: user)
    allow_any_instance_of(ApplicationController).to receive(:authenticated?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:resume_session).and_return(session)
    allow(Current).to receive(:session).and_return(session)
    allow(Current).to receive(:user).and_return(user)
  end

  def sign_out
    allow_any_instance_of(ApplicationController).to receive(:authenticated?).and_return(false)
    allow_any_instance_of(ApplicationController).to receive(:resume_session).and_return(nil)
    allow(Current).to receive(:session).and_return(nil)
    allow(Current).to receive(:user).and_return(nil)
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :controller
  config.include AuthenticationHelpers, type: :request
end