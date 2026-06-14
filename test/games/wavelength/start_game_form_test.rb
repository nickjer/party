# frozen_string_literal: true

require "test_helper"

module Wavelength
  class StartGameFormTest < ActiveSupport::TestCase
    test "#valid? returns true when both teams have two players" do
      game = build(:wl_game, :with_teams)

      assert_predicate StartGameForm.new(game:), :valid?
    end

    test "#valid? returns false once the game has started" do
      game = build(:wl_guessing_game)

      form = StartGameForm.new(game:)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:base, message: "Game has already started")
    end

    test "#valid? requires at least two players on each team" do
      game = build(:wl_game)
      game.add_player(user_id: "u1", name: PlayerName.parse("RedOne"),
        team: Team.red)
      game.add_player(user_id: "u2", name: PlayerName.parse("BlueOne"),
        team: Team.blue)

      form = StartGameForm.new(game:)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:base,
        message: "Red team needs at least 2 players")
      assert form.errors.added?(:base,
        message: "Blue team needs at least 2 players")
    end
  end
end
