# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class EditPlayerFormTest < ActiveSupport::TestCase
    test "#errors returns Errors instance" do
      game = build(:lq_game)
      player = build(:lq_player, game:)
      form = EditPlayerForm.new(game:, current_player: player)

      assert_instance_of Errors, form.errors
    end

    test "#name returns NormalizedString instance" do
      game = build(:lq_game)
      player = build(:lq_player, game:)
      form = EditPlayerForm.new(game:, current_player: player, name: "Bob")

      assert_instance_of NormalizedString, form.name
    end

    test "#valid? normalizes name with NormalizedString" do
      game = build(:lq_game)
      player = build(:lq_player, game:)

      form = EditPlayerForm.new(game:, current_player: player,
        name: "  Bob  ")

      assert_predicate form, :valid?
      assert_equal "Bob", form.name.to_s
    end

    test "#valid? returns false when name already taken by other player" do
      game = build(:lq_polling_game, player_names: %w[Alice Bob])
      alice = game.players.find { |p| p.name.to_s == "Alice" }

      form = EditPlayerForm.new(game:, current_player: alice, name: "Bob")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:name, message: "has already been taken")
    end

    test "#valid? returns false when name already taken with different " \
      "casing" do
      game = build(:lq_polling_game, player_names: %w[Alice Bob])
      alice = game.players.find { |p| p.name.to_s == "Alice" }

      form = EditPlayerForm.new(game:, current_player: alice, name: "bob")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:name, message: "has already been taken")
    end

    test "#valid? returns false with blank name" do
      game = build(:lq_game)
      player = build(:lq_player, game:)

      form = EditPlayerForm.new(game:, current_player: player, name: "")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:name,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with name too long" do
      game = build(:lq_game)
      player = build(:lq_player, game:)

      form = EditPlayerForm.new(game:, current_player: player,
        name: "a" * 26)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:name,
        message: "is too long (maximum is 25 characters)")
    end

    test "#valid? returns false with name too short" do
      game = build(:lq_game)
      player = build(:lq_player, game:)

      form = EditPlayerForm.new(game:, current_player: player, name: "ab")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:name,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? returns true when keeping current name" do
      game = build(:lq_polling_game, player_names: %w[Alice Bob])
      alice = game.players.find { |p| p.name.to_s == "Alice" }

      form = EditPlayerForm.new(game:, current_player: alice, name: "Alice")

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true with name at maximum length" do
      game = build(:lq_game)
      player = build(:lq_player, game:)

      form = EditPlayerForm.new(game:, current_player: player,
        name: "a" * 25)

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true with name at minimum length" do
      game = build(:lq_game)
      player = build(:lq_player, game:)

      form = EditPlayerForm.new(game:, current_player: player, name: "Bob")

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true with unique name" do
      game = build(:lq_polling_game, player_names: %w[Alice Bob])
      alice = game.players.find { |p| p.name.to_s == "Alice" }

      form = EditPlayerForm.new(game:, current_player: alice,
        name: "Charlie")

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end
  end
end
