# frozen_string_literal: true

require "test_helper"

class PlayerConnectionsTest < ActiveSupport::TestCase
  setup do
    # Create a fresh instance for each test (not using the singleton)
    @connections = PlayerConnections.send(:new)
  end

  # Count tests

  test "#count returns 0 for player with no connections" do
    player_id = 123

    assert_equal 0, @connections.count(player_id)
  end

  test "#count returns current connection count for player" do
    player_id = 123
    @connections.increment(player_id)
    @connections.increment(player_id)

    assert_equal 2, @connections.count(player_id)
  end

  test "#count works with different player IDs" do
    player_id_1 = 123
    player_id_2 = 456

    @connections.increment(player_id_1)
    @connections.increment(player_id_2)
    @connections.increment(player_id_2)

    assert_equal 1, @connections.count(player_id_1)
    assert_equal 2, @connections.count(player_id_2)
  end

  # Increment tests

  test "#increment increases count from 0 to 1" do
    player_id = 123

    result = @connections.increment(player_id)

    assert_equal 1, result
    assert_equal 1, @connections.count(player_id)
  end

  test "#increment increases count from existing value" do
    player_id = 123
    @connections.increment(player_id)

    result = @connections.increment(player_id)

    assert_equal 2, result
    assert_equal 2, @connections.count(player_id)
  end

  test "#increment can be called multiple times" do
    player_id = 123

    @connections.increment(player_id)
    @connections.increment(player_id)
    @connections.increment(player_id)

    assert_equal 3, @connections.count(player_id)
  end

  test "#increment returns the new count" do
    player_id = 123

    result1 = @connections.increment(player_id)
    result2 = @connections.increment(player_id)
    result3 = @connections.increment(player_id)

    assert_equal 1, result1
    assert_equal 2, result2
    assert_equal 3, result3
  end

  test "#increment works independently for different players" do
    player_id_1 = 123
    player_id_2 = 456

    @connections.increment(player_id_1)
    @connections.increment(player_id_1)
    @connections.increment(player_id_2)

    assert_equal 2, @connections.count(player_id_1)
    assert_equal 1, @connections.count(player_id_2)
  end

  # Decrement tests

  test "#decrement decreases count by 1" do
    player_id = 123
    @connections.increment(player_id)
    @connections.increment(player_id)

    result = @connections.decrement(player_id)

    assert_equal 1, result
    assert_equal 1, @connections.count(player_id)
  end

  test "#decrement returns the new count" do
    player_id = 123
    @connections.increment(player_id)
    @connections.increment(player_id)
    @connections.increment(player_id)

    result1 = @connections.decrement(player_id)
    result2 = @connections.decrement(player_id)

    assert_equal 2, result1
    assert_equal 1, result2
  end

  test "#decrement never goes below 0" do
    player_id = 123

    result = @connections.decrement(player_id)

    assert_equal 0, result
    assert_equal 0, @connections.count(player_id)
  end

  test "#decrement stops at 0 when called multiple times on empty count" do
    player_id = 123

    @connections.decrement(player_id)
    @connections.decrement(player_id)
    @connections.decrement(player_id)

    assert_equal 0, @connections.count(player_id)
  end

  test "#decrement stops at 0 when decreasing from 1" do
    player_id = 123
    @connections.increment(player_id)

    @connections.decrement(player_id)

    assert_equal 0, @connections.count(player_id)
  end

  test "#decrement stops at 0 and stays there" do
    player_id = 123
    @connections.increment(player_id)
    @connections.decrement(player_id)

    result = @connections.decrement(player_id)

    assert_equal 0, result
    assert_equal 0, @connections.count(player_id)
  end

  test "#decrement works independently for different players" do
    player_id_1 = 123
    player_id_2 = 456

    @connections.increment(player_id_1)
    @connections.increment(player_id_1)
    @connections.increment(player_id_2)
    @connections.increment(player_id_2)
    @connections.increment(player_id_2)

    @connections.decrement(player_id_1)
    @connections.decrement(player_id_2)
    @connections.decrement(player_id_2)

    assert_equal 1, @connections.count(player_id_1)
    assert_equal 1, @connections.count(player_id_2)
  end

  # Singleton tests

  test "PlayerConnections is a singleton" do
    instance1 = PlayerConnections.instance
    instance2 = PlayerConnections.instance

    assert_same instance1, instance2
  end

  test "singleton instance persists state across calls" do
    PlayerConnections.instance.increment(999)

    assert_equal 1, PlayerConnections.instance.count(999)
  end
end
