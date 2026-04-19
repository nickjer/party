# frozen_string_literal: true

require "test_helper"

class PlayerNameTest < ActiveSupport::TestCase
  test ".parse normalizes and length-validates" do
    player_name = PlayerName.parse("  Alice  ")

    assert_equal "Alice", player_name.to_s
  end

  test ".parse raises when too short" do
    assert_raises(ArgumentError) { PlayerName.parse("ab") }
  end

  test ".parse raises when too long" do
    assert_raises(ArgumentError) { PlayerName.parse("a" * 26) }
  end

  test ".parse raises on blank input" do
    assert_raises(ArgumentError) { PlayerName.parse("") }
  end

  test "#initialize accepts a pre-normalized NormalizedString" do
    normalized = NormalizedString.new("Bob")

    player_name = PlayerName.new(normalized)

    assert_equal "Bob", player_name.to_s
  end

  test "#initialize raises when normalized length is out of bounds" do
    assert_raises(ArgumentError) { PlayerName.new(NormalizedString.new("ab")) }
  end

  test "#== is case-insensitive between PlayerName instances" do
    assert_equal PlayerName.parse("Alice"), PlayerName.parse("alice")
  end

  test "#== ignores non-word characters" do
    assert_equal PlayerName.parse("Jean-Luc"), PlayerName.parse("JeanLuc")
  end

  test "#== returns false for different names" do
    assert_not_equal PlayerName.parse("Alice"), PlayerName.parse("Bob")
  end

  test "#<=> orders alphabetically case-insensitively" do
    names = [
      PlayerName.parse("Charlie"),
      PlayerName.parse("alice"),
      PlayerName.parse("BOB")
    ].sort.map(&:to_s)

    assert_equal %w[alice BOB Charlie], names
  end

  test "#hash is equal for equal names" do
    assert_equal PlayerName.parse("Alice").hash, PlayerName.parse("alice").hash
  end

  test "#hash allows use as Set element" do
    set = Set.new
    set << PlayerName.parse("Alice")
    set << PlayerName.parse("alice")
    set << PlayerName.parse("Bob")

    assert_equal 2, set.size
  end

  test "#eql? mirrors #==" do
    assert PlayerName.parse("Alice").eql?(PlayerName.parse("alice"))
    assert_not PlayerName.parse("Alice").eql?(PlayerName.parse("Bob"))
  end
end
