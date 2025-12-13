# frozen_string_literal: true

require "simplecov"
SimpleCov.start "rails" do
  add_group "Burn Unit", "app/games/burn_unit"
  add_group "Loaded Questions", "app/games/loaded_questions"
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "faker"
require "mocha/minitest"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in
    # alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    include FactoryBot::Syntax::Methods

    parallelize_setup do |worker|
      SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}"
    end

    parallelize_teardown do
      SimpleCov.result
    end

    setup do
      # Reset PlayerConnections to a fresh instance for each test
      @player_connections = ::PlayerConnections.send(:new)
      ::PlayerConnections.stubs(:instance).returns(@player_connections)
    end

    def sign_in(user_id)
      test_request = ActionDispatch::TestRequest.create
      test_request.cookie_jar.encrypted[:current_user_id] = user_id
      cookies[:current_user_id] = test_request.cookie_jar[:current_user_id]
    end

    def reload(game:)
      game.class.find(game.id)
    end
  end
end
