# frozen_string_literal: true

require "test_helper"

module Codenames
  class NewPlayerFormTest < ActiveSupport::TestCase
    test "#valid? returns true for a unique name and user" do
      game = build(:cn_game)

      form = NewPlayerForm.new(game:, user_id: "u1", name: "Alice")

      assert_predicate form, :valid?
      assert_instance_of PlayerName, form.player_name
    end

    test "#valid? returns false for a duplicate name in the game" do
      game = build(:cn_game)
      game.add_player(user_id: "u1", name: PlayerName.parse("Alice"))

      form = NewPlayerForm.new(game:, user_id: "u2", name: "alice")

      assert_not_predicate form, :valid?
    end

    test "#valid? returns false when the user already joined" do
      game = build(:cn_game)
      game.add_player(user_id: "u1", name: PlayerName.parse("Alice"))

      form = NewPlayerForm.new(game:, user_id: "u1", name: "Bob")

      assert_not_predicate form, :valid?
    end

    test "#valid? returns false for a name too short" do
      game = build(:cn_game)

      form = NewPlayerForm.new(game:, user_id: "u1", name: "ab")

      assert_not_predicate form, :valid?
    end
  end
end
