require 'simplecov'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/reporters'
Minitest::Reporters.use!

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical
  # order
  fixtures :all

  # Returns true if a test user is logged in.
  def is_logged_in? # rubocop:disable Naming/PredicateName
    !session[:user_id].nil?
  end

  # Log in as a particular user.
  def log_in_as(user)
    session[:user_id] = user.id
  end
end

class ActionDispatch::IntegrationTest
  # Log in as a particular user.
  def log_in_as(user, password: 'foobarbaz123', remember_me: '1')
    post login_path, params: { email: user.email,
                               password: password,
                               remember_me: remember_me }
  end
end
