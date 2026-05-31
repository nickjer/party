# frozen_string_literal: true

require "test_helper"

module Codenames
  class PlayerTest < ActiveSupport::TestCase
    test ".build creates a teamless, non-spymaster player by default" do
      player = Player.build(game_id: "g1", user_id: "u1",
        name: PlayerName.parse("Alice"))

      assert_nil player.team
      assert_not_predicate player, :spymaster?
    end

    test "#team= and #spymaster= update the document" do
      player = Player.build(game_id: "g1", user_id: "u1",
        name: PlayerName.parse("Alice"))

      player.team = Team.red
      player.spymaster = true

      assert_equal Team.red, player.team
      assert_predicate player, :spymaster?
    end

    test "#operative? is true only for a non-spymaster with a team" do
      player = Player.build(game_id: "g1", user_id: "u1",
        name: PlayerName.parse("Alice"))

      assert_not_predicate player, :operative?

      player.team = Team.blue
      assert_predicate player, :operative?

      player.spymaster = true
      assert_not_predicate player, :operative?
    end

    test "#online? reflects PlayerConnections" do
      player = Player.build(game_id: "g1", user_id: "u1",
        name: PlayerName.parse("Alice"), id: "p1")

      assert_not_predicate player, :online?

      PlayerConnections.instance.increment("p1")
      assert_predicate player, :online?
    end

    test "#<=> orders by team (red, then blue, then teamless), then name" do
      red_bart = Player.build(game_id: "g1", user_id: "u1",
        name: PlayerName.parse("Bart"), team: Team.red)
      red_alice = Player.build(game_id: "g1", user_id: "u2",
        name: PlayerName.parse("Alice"), team: Team.red)
      blue_cleo = Player.build(game_id: "g1", user_id: "u3",
        name: PlayerName.parse("Cleo"), team: Team.blue)
      teamless_dana = Player.build(game_id: "g1", user_id: "u4",
        name: PlayerName.parse("Dana"))

      sorted = [blue_cleo, teamless_dana, red_bart, red_alice].sort

      assert_equal(%w[Alice Bart Cleo Dana],
        sorted.map { |player| player.name.to_s })
    end

    test "#== compares by id" do
      one = Player.build(game_id: "g1", user_id: "u1",
        name: PlayerName.parse("Alice"), id: "p1")
      two = Player.build(game_id: "g1", user_id: "u2",
        name: PlayerName.parse("Bob"), id: "p1")

      assert_equal one, two
    end
  end
end
