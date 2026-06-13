# frozen_string_literal: true

require "test_helper"

module Wavelength
  class Game
    class StatusTest < ActiveSupport::TestCase
      test ".setup returns setup status" do
        assert_predicate Status.setup, :setup?
        assert_not_predicate Status.setup, :guessing?
      end

      test ".guessing returns guessing status" do
        assert_predicate Status.guessing, :guessing?
        assert_not_predicate Status.guessing, :left_right?
      end

      test ".left_right returns left_right status" do
        assert_predicate Status.left_right, :left_right?
        assert_not_predicate Status.left_right, :reveal?
      end

      test ".reveal returns reveal status" do
        assert_predicate Status.reveal, :reveal?
        assert_not_predicate Status.reveal, :completed?
      end

      test ".completed returns completed status" do
        assert_predicate Status.completed, :completed?
        assert_not_predicate Status.completed, :setup?
      end

      test ".parse builds status from a string" do
        assert_predicate Status.parse("setup"), :setup?
        assert_predicate Status.parse("guessing"), :guessing?
        assert_predicate Status.parse("left_right"), :left_right?
        assert_predicate Status.parse("reveal"), :reveal?
        assert_predicate Status.parse("completed"), :completed?
      end

      test ".parse raises for an unknown status" do
        assert_raises(ArgumentError) { Status.parse("nope") }
      end

      test ".new is private" do
        assert_raises(NoMethodError) { Status.new(:setup) }
      end

      test "#== compares by value" do
        assert_equal Status.setup, Status.setup
        assert_not_equal Status.setup, Status.guessing
      end

      test "#to_s and #as_json return the status name" do
        assert_equal "guessing", Status.guessing.to_s
        assert_equal "left_right", Status.left_right.as_json
      end

      test "#eql? and #hash allow statuses as hash keys" do
        counts = { Status.setup => 1, Status.reveal => 2 }

        assert_equal 1, counts[Status.setup]
        assert_equal 2, counts[Status.reveal]
      end
    end
  end
end
