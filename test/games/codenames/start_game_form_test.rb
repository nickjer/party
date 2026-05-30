# frozen_string_literal: true

require "test_helper"

module Codenames
  class StartGameFormTest < ActiveSupport::TestCase
    test "#valid? returns true when both teams are staffed" do
      game = build(:cn_game, :with_teams)

      assert_predicate StartGameForm.new(game:), :valid?
    end

    test "#valid? returns false once the game has started" do
      game = build(:cn_playing_game)

      form = StartGameForm.new(game:)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:base, message: "Game has already started")
    end

    test "#valid? requires a spymaster on each team" do
      game = build(:cn_game)
      game.add_player(user_id: "u1", name: PlayerName.parse("RedOp"),
        team: Team.red)
      game.add_player(user_id: "u2", name: PlayerName.parse("BlueOp"),
        team: Team.blue)

      form = StartGameForm.new(game:)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:base, message: "Red team needs one spymaster")
      assert form.errors.added?(:base, message: "Blue team needs one spymaster")
    end

    test "#valid? requires an operative on each team" do
      game = build(:cn_game)
      game.add_player(user_id: "u1", name: PlayerName.parse("RedSpy"),
        team: Team.red, spymaster: true)
      game.add_player(user_id: "u2", name: PlayerName.parse("BlueSpy"),
        team: Team.blue, spymaster: true)

      form = StartGameForm.new(game:)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:base, message: "Red team needs an operative")
      assert form.errors.added?(:base, message: "Blue team needs an operative")
    end
  end
end
