# frozen_string_literal: true

require "test_helper"

module Codenames
  class Game
    class IdentityTest < ActiveSupport::TestCase
      test ".agent returns the agent identity for a team" do
        assert_equal Team.red, Identity.agent(Team.red).team
        assert_equal Team.blue, Identity.agent(Team.blue).team
      end

      test "#agent? is true for red and blue" do
        assert_predicate Identity.red, :agent?
        assert_predicate Identity.blue, :agent?
        assert_not_predicate Identity.bystander, :agent?
        assert_not_predicate Identity.assassin, :agent?
      end

      test "#team returns the team for agents and nil otherwise" do
        assert_equal Team.red, Identity.red.team
        assert_equal Team.blue, Identity.blue.team
        assert_nil Identity.bystander.team
        assert_nil Identity.assassin.team
      end

      test "#assassin? and #bystander? predicates" do
        assert_predicate Identity.assassin, :assassin?
        assert_predicate Identity.bystander, :bystander?
        assert_not_predicate Identity.red, :assassin?
      end

      test ".parse round-trips the kind" do
        %w[red blue bystander assassin].each do |kind|
          assert_equal kind, Identity.parse(kind).to_s
        end
      end

      test ".parse raises for an unknown identity" do
        assert_raises(ArgumentError) { Identity.parse("double") }
      end

      test "#== compares by kind" do
        assert_equal Identity.red, Identity.red
        assert_not_equal Identity.red, Identity.blue
      end
    end
  end
end
