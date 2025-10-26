# frozen_string_literal: true

require "test_helper"

module BurnUnit
  class EditPlayerFormTest < ActiveSupport::TestCase
    test "#valid? returns true with valid unique name" do
      game = build(:bu_polling_game, player_names: %w[Alice Bob])
      current_player = game.players.first
      form = EditPlayerForm.new(game:, current_player:, name: "Charlie")

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true when keeping same name" do
      game = build(:bu_polling_game, player_names: %w[Alice Bob])
      current_player = game.players.find { |p| p.name.to_s == "Alice" }
      form = EditPlayerForm.new(game:, current_player:, name: "Alice")

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true with name at minimum length" do
      game = build(:bu_polling_game, player_names: %w[Alice])
      current_player = game.players.first
      form = EditPlayerForm.new(game:, current_player:, name: "Bob")

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true with name at maximum length" do
      game = build(:bu_polling_game, player_names: %w[Alice])
      current_player = game.players.first
      form = EditPlayerForm.new(game:, current_player:, name: "a" * 25)

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns false with name too short" do
      game = build(:bu_polling_game, player_names: %w[Alice])
      current_player = game.players.first
      form = EditPlayerForm.new(game:, current_player:, name: "ab")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:name, message:
        "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with blank name" do
      game = build(:bu_polling_game, player_names: %w[Alice])
      current_player = game.players.first
      form = EditPlayerForm.new(game:, current_player:, name: "")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:name, message:
        "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with name too long" do
      game = build(:bu_polling_game, player_names: %w[Alice])
      current_player = game.players.first
      form = EditPlayerForm.new(game:, current_player:, name: "a" * 26)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:name, message:
        "is too long (maximum is 25 characters)")
    end

    test "#valid? returns false when name taken by another player" do
      game = build(:bu_polling_game, player_names: %w[Alice Bob])
      current_player = game.players.find { |p| p.name.to_s == "Alice" }
      form = EditPlayerForm.new(game:, current_player:, name: "Bob")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:name, message: "has already been taken")
    end

    test "#valid? returns false when name taken by another player with " \
      "different casing" do
      game = build(:bu_polling_game, player_names: %w[Alice Bob])
      current_player = game.players.find { |p| p.name.to_s == "Alice" }
      form = EditPlayerForm.new(game:, current_player:, name: "bob")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:name, message: "has already been taken")
    end

    test "#valid? normalizes name with NormalizedString" do
      game = build(:bu_polling_game, player_names: %w[Alice])
      current_player = game.players.first
      form = EditPlayerForm.new(game:, current_player:, name: "  Bob  ")

      assert_predicate form, :valid?
      assert_equal "Bob", form.name.to_s
    end

    test "#initialize uses current player name when name is nil" do
      game = build(:bu_polling_game, player_names: %w[Alice])
      current_player = game.players.first
      form = EditPlayerForm.new(game:, current_player:, name: nil)

      assert_equal "Alice", form.name.to_s
    end

    test "#name returns NormalizedString instance" do
      game = build(:bu_polling_game, player_names: %w[Alice])
      current_player = game.players.first
      form = EditPlayerForm.new(game:, current_player:, name: "Bob")

      assert_instance_of NormalizedString, form.name
    end

    test "#errors returns Errors instance" do
      game = build(:bu_polling_game, player_names: %w[Alice])
      current_player = game.players.first
      form = EditPlayerForm.new(game:, current_player:, name: "Bob")

      assert_instance_of Errors, form.errors
    end
  end
end
