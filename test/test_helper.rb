ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module ApiAuthHelpers
  def auth_headers_for(user, school: nil)
    token = Auth::JwtToken.encode(
      user_id: user.id,
      school_id: school&.id,
      role_names: user.roles.pluck(:name)
    )
    { "Authorization" => "Bearer #{token}" }
  end
end

class ActionDispatch::IntegrationTest
  include ApiAuthHelpers
end
