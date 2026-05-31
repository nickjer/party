# frozen_string_literal: true

require "test_helper"

module Codenames
  class Game
    class StatusTest < ActiveSupport::TestCase
      test ".setup returns setup status" do
        assert_predicate Status.setup, :setup?
        assert_not_predicate Status.setup, :playing?
      end

      test ".playing returns playing status" do
        assert_predicate Status.playing, :playing?
        assert_not_predicate Status.playing, :completed?
      end

      test ".completed returns completed status" do
        assert_predicate Status.completed, :completed?
        assert_not_predicate Status.completed, :setup?
      end

      test ".parse builds status from a string" do
        assert_predicate Status.parse("setup"), :setup?
        assert_predicate Status.parse("playing"), :playing?
        assert_predicate Status.parse("completed"), :completed?
      end

      test ".parse raises for an unknown status" do
        assert_raises(ArgumentError) { Status.parse("nope") }
      end

      test "#== compares by value" do
        assert_equal Status.setup, Status.setup
        assert_not_equal Status.setup, Status.playing
      end

      test "#to_s returns the status name" do
        assert_equal "playing", Status.playing.to_s
      end

      test ".new is private" do
        assert_raises(NoMethodError) { Status.new(:setup) }
      end
    end
  end
end
