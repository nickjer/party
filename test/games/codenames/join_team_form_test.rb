# frozen_string_literal: true

require "test_helper"

module Codenames
  class JoinTeamFormTest < ActiveSupport::TestCase
    def teamless_player(game)
      game.add_player(user_id: "u9", name: PlayerName.parse("Newbie"))
    end

    test "#valid? returns true when joining a team as an operative" do
      game = build(:cn_game)
      player = teamless_player(game)

      form = JoinTeamForm.new(game:, current_player: player, team: "red")

      assert_predicate form, :valid?
      assert_equal Team.red, form.team
      assert_not form.spymaster
    end

    test "#valid? casts the spymaster flag" do
      game = build(:cn_game)
      player = teamless_player(game)

      form = JoinTeamForm.new(game:, current_player: player, team: "blue",
        spymaster: "true")

      assert_predicate form, :valid?
      assert form.spymaster
    end

    test "#valid? returns false for an unknown team" do
      game = build(:cn_game)
      player = teamless_player(game)

      form = JoinTeamForm.new(game:, current_player: player, team: "green")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:team, message: "must be red or blue")
    end

    test "#valid? rejects a second spymaster on a team" do
      game = build(:cn_game, :with_teams) # RedSpy already a spymaster
      player = teamless_player(game)

      form = JoinTeamForm.new(game:, current_player: player, team: "red",
        spymaster: "true")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:spymaster,
        message: "red team already has a spymaster")
    end

    test "#valid? allows the existing spymaster to re-affirm their seat" do
      game = build(:cn_game, :with_teams)
      red_spy = game.spymaster_for(Team.red)

      form = JoinTeamForm.new(game:, current_player: red_spy, team: "red",
        spymaster: "true")

      assert_predicate form, :valid?
    end

    test "#valid? rejects spymaster requests once playing" do
      game = build(:cn_playing_game)
      player = teamless_player(game)

      form = JoinTeamForm.new(game:, current_player: player, team: "red",
        spymaster: "true")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:spymaster,
        message: "roles are locked once the game starts")
    end

    test "#valid? rejects switching teams once playing" do
      game = build(:cn_playing_game)
      red_op = game.operatives.find { |player| player.team == Team.red }

      form = JoinTeamForm.new(game:, current_player: red_op, team: "blue")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:base,
        message: "Teams are locked once the game starts")
    end

    test "#valid? lets a teamless player join mid-game as an operative" do
      game = build(:cn_playing_game)
      player = teamless_player(game)

      form = JoinTeamForm.new(game:, current_player: player, team: "blue")

      assert_predicate form, :valid?
    end
  end
end
