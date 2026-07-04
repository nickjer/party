# frozen_string_literal: true

require "test_helper"

class ApplicationRecordTest < ActiveSupport::TestCase
  test ".generate_unique_id retries when the generated id is already taken" do
    existing = create(:user)
    SecureRandom.stubs(:alphanumeric).with(6).returns(existing.id, "fresh1")

    assert_equal "fresh1", User.generate_unique_id
  end
end
