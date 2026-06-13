# frozen_string_literal: true

require "test_helper"

module Wavelength
  class PlayerTest < ActiveSupport::TestCase
    test ".build creates a teamless player with zero psychic_count" do
      player = Player.build(game_id: "g1", user_id: "u1",
        name: PlayerName.parse("Alice"))

      assert_nil player.team
      assert_equal 0, player.psychic_count
    end

    test "#team= updates the document" do
      player = Player.build(game_id: "g1", user_id: "u1",
        name: PlayerName.parse("Alice"))

      player.team = Team.red

      assert_equal Team.red, player.team
    end

    test "#increment_psychic_count bumps the counter" do
      player = Player.build(game_id: "g1", user_id: "u1",
        name: PlayerName.parse("Alice"))

      player.increment_psychic_count
      player.increment_psychic_count

      assert_equal 2, player.psychic_count
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

    test "#to_global_id builds a Player GID" do
      player = Player.build(game_id: "g1", user_id: "u1",
        name: PlayerName.parse("Alice"), id: "p1")

      assert_equal "Player", player.to_global_id.model_name
      assert_equal "p1", player.to_global_id.model_id
    end
  end
end
