# frozen_string_literal: true

require "test_helper"

module Codenames
  class TeamTest < ActiveSupport::TestCase
    test ".red and .blue build the two teams" do
      assert_predicate Team.red, :red?
      assert_predicate Team.blue, :blue?
    end

    test ".parse builds a team from a string" do
      assert_equal Team.red, Team.parse("red")
      assert_equal Team.blue, Team.parse("blue")
    end

    test ".parse raises for an unknown team" do
      assert_raises(ArgumentError) { Team.parse("green") }
    end

    test "#opponent returns the other team" do
      assert_equal Team.blue, Team.red.opponent
      assert_equal Team.red, Team.blue.opponent
    end

    test "#== compares by color" do
      assert_equal Team.red, Team.red
      assert_not_equal Team.red, Team.blue
    end

    test "#== is false for non-team values" do
      assert_not_equal Team.red, "red"
      assert_not_equal Team.red, nil
    end

    test "#to_s and #as_json return the color name" do
      assert_equal "red", Team.red.to_s
      assert_equal "blue", Team.blue.as_json
    end

    test "teams can be used as hash keys" do
      counts = { Team.red => 9, Team.blue => 8 }

      assert_equal 9, counts[Team.red]
      assert_equal 8, counts[Team.blue]
    end

    test ".new is private" do
      assert_raises(NoMethodError) { Team.new(:red) }
    end
  end
end
