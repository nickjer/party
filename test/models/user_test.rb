require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "#valid? returns false when last_seen_at is nil" do
    user = build(:user, last_seen_at: nil)

    assert_not user.valid?
    assert user.errors.added?(:last_seen_at, :blank)
  end
end
