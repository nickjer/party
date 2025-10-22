# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class NewPlayerFormTest < ActiveSupport::TestCase
    test "#valid? returns true with valid unique name and new user" do
      game = build(:lq_game)
      user_id = "user1"

      form = NewPlayerForm.new(game:, user_id:, name: "Bob")

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true with name at minimum length" do
      game = build(:lq_game)
      user_id = "user1"

      form = NewPlayerForm.new(game:, user_id:, name: "Bob")

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true with name at maximum length" do
      game = build(:lq_game)
      user_id = "user1"

      form = NewPlayerForm.new(game:, user_id:, name: "a" * 25)

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns false with name too short" do
      game = build(:lq_game)
      user_id = "user1"

      form = NewPlayerForm.new(game:, user_id:, name: "ab")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:name,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with blank name" do
      game = build(:lq_game)
      user_id = "user1"

      form = NewPlayerForm.new(game:, user_id:, name: "")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:name,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with nil name" do
      game = build(:lq_game)
      user_id = "user1"

      form = NewPlayerForm.new(game:, user_id:, name: nil)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:name,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with name too long" do
      game = build(:lq_game)
      user_id = "user1"

      form = NewPlayerForm.new(game:, user_id:, name: "a" * 26)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:name,
        message: "is too long (maximum is 25 characters)")
    end

    test "#valid? returns false when name already taken" do
      game = build(:lq_polling_game, player_names: %w[Bob])
      user_id = "user1"

      form = NewPlayerForm.new(game:, user_id:, name: "Bob")

      assert(game.players.any? { |player| player.name == form.name })
      assert_not_predicate form, :valid?
      assert form.errors.added?(:name, message: "has already been taken")
    end

    test "#valid? returns false when name already taken with different " \
      "casing" do
      game = build(:lq_polling_game, player_names: %w[Bob])
      user_id = "user1"

      form = NewPlayerForm.new(game:, user_id:, name: "bob")

      assert(game.players.any? { |player| player.name == form.name })
      assert_not_predicate form, :valid?
      assert form.errors.added?(:name, message: "has already been taken")
    end

    test "#valid? returns false when user already joined game" do
      game = build(:lq_polling_game)
      existing_player = game.players.first
      user_id = existing_player.user_id

      form = NewPlayerForm.new(game:, user_id:, name: "NewName")

      assert game.player_for(user_id)
      assert_not_predicate form, :valid?
      assert form.errors.added?(:base,
        message: "You have already joined this game")
    end

    test "#valid? normalizes name with NormalizedString" do
      game = build(:lq_game)
      user_id = "user1"

      form = NewPlayerForm.new(game:, user_id:, name: "  Bob  ")

      assert_predicate form, :valid?
      assert_equal "Bob", form.name.to_s
    end

    test "#name returns NormalizedString instance" do
      game = build(:lq_game)
      user_id = "user1"
      form = NewPlayerForm.new(game:, user_id:, name: "Bob")

      assert_instance_of NormalizedString, form.name
    end

    test "#errors returns Errors instance" do
      game = build(:lq_game)
      user_id = "user1"
      form = NewPlayerForm.new(game:, user_id:, name: "Bob")

      assert_instance_of Errors, form.errors
    end
  end
end
