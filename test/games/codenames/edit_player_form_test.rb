# frozen_string_literal: true

require "test_helper"

module Codenames
  class EditPlayerFormTest < ActiveSupport::TestCase
    test "#valid? returns true for a new unique name" do
      game = build(:cn_game)
      player = game.add_player(user_id: "u1", name: PlayerName.parse("Alice"))

      form = EditPlayerForm.new(game:, current_player: player, name: "Alicia")

      assert_predicate form, :valid?
    end

    test "#valid? allows keeping the same name" do
      game = build(:cn_game)
      player = game.add_player(user_id: "u1", name: PlayerName.parse("Alice"))

      form = EditPlayerForm.new(game:, current_player: player, name: "Alice")

      assert_predicate form, :valid?
    end

    test "#valid? returns false for a name taken by another player" do
      game = build(:cn_game)
      player = game.add_player(user_id: "u1", name: PlayerName.parse("Alice"))
      game.add_player(user_id: "u2", name: PlayerName.parse("Bob"))

      form = EditPlayerForm.new(game:, current_player: player, name: "Bob")

      assert_not_predicate form, :valid?
    end
  end
end
