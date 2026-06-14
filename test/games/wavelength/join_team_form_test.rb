# frozen_string_literal: true

require "test_helper"

module Wavelength
  class JoinTeamFormTest < ActiveSupport::TestCase
    test "#valid? returns true when joining a team" do
      game = build(:wl_game)
      player = teamless_player(game)

      form = JoinTeamForm.new(game:, current_player: player, team: "red")

      assert_predicate form, :valid?
      assert_equal Team.red, form.team
    end

    test "#valid? returns false for an unknown team" do
      game = build(:wl_game)
      player = teamless_player(game)

      form = JoinTeamForm.new(game:, current_player: player, team: "green")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:team, message: "must be red or blue")
    end

    test "#valid? returns false for a missing team" do
      game = build(:wl_game)
      player = teamless_player(game)

      form = JoinTeamForm.new(game:, current_player: player)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:team, message: "must be red or blue")
    end

    test "#valid? rejects switching teams once playing" do
      game = build(:wl_guessing_game)
      red_player = game.players_on(Team.red).first

      form = JoinTeamForm.new(game:, current_player: red_player, team: "blue")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:base,
        message: "Teams are locked once the game starts")
    end

    test "#valid? lets a teamless player join mid-game" do
      game = build(:wl_guessing_game)
      player = teamless_player(game)

      form = JoinTeamForm.new(game:, current_player: player, team: "blue")

      assert_predicate form, :valid?
    end

    test "#valid? rejects joining once the game is over" do
      game = build(:wl_completed_game)
      player = teamless_player(game)

      form = JoinTeamForm.new(game:, current_player: player, team: "blue")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:base, message: "Game is over")
    end

    private

    def teamless_player(game)
      game.add_player(user_id: "u9", name: PlayerName.parse("Newbie"))
    end
  end
end
