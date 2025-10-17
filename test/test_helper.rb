# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "faker"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in
    # alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    include FactoryBot::Syntax::Methods

    def sign_in(user)
      test_request = ActionDispatch::TestRequest.create
      test_request.cookie_jar.encrypted[:current_user_id] = user.id
      cookies[:current_user_id] = test_request.cookie_jar[:current_user_id]
    end
  end
end
