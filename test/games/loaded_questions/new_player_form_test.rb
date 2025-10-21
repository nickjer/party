# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class NewPlayerFormTest < ActiveSupport::TestCase
    test "#valid? returns true with valid unique name and new user" do
      game = create(:lq_game)
      user = create(:user)

      form = NewPlayerForm.new(game:, user:, name: "Bob")

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true with name at minimum length" do
      game = create(:lq_game)
      user = create(:user)

      form = NewPlayerForm.new(game:, user:, name: "Bob")

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true with name at maximum length" do
      game = create(:lq_game)
      user = create(:user)

      form = NewPlayerForm.new(game:, user:, name: "a" * 25)

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns false with name too short" do
      game = create(:lq_game)
      user = create(:user)

      form = NewPlayerForm.new(game:, user:, name: "ab")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:name,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with blank name" do
      game = create(:lq_game)
      user = create(:user)

      form = NewPlayerForm.new(game:, user:, name: "")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:name,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with nil name" do
      game = create(:lq_game)
      user = create(:user)

      form = NewPlayerForm.new(game:, user:, name: nil)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:name,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with name too long" do
      game = create(:lq_game)
      user = create(:user)

      form = NewPlayerForm.new(game:, user:, name: "a" * 26)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:name,
        message: "is too long (maximum is 25 characters)")
    end

    test "#valid? returns false when name already taken" do
      game = create(:lq_game, player_names: %w[Bob])
      user = create(:user)

      form = NewPlayerForm.new(game:, user:, name: "Bob")

      assert(game.players.any? { |player| player.name == form.name })
      assert_not_predicate form, :valid?
      assert form.errors.added?(:name, message: "has already been taken")
    end

    test "#valid? returns false when name already taken with different " \
      "casing" do
      game = create(:lq_game, player_names: %w[Bob])
      user = create(:user)

      form = NewPlayerForm.new(game:, user:, name: "bob")

      assert(game.players.any? { |player| player.name == form.name })
      assert_not_predicate form, :valid?
      assert form.errors.added?(:name, message: "has already been taken")
    end

    test "#valid? returns false when user already joined game" do
      existing_user = create(:user)
      game = create(:lq_game, user: existing_user)

      form = NewPlayerForm.new(game:, user: existing_user, name: "NewName")

      assert game.player_for(existing_user)
      assert_not_predicate form, :valid?
      assert form.errors.added?(:base,
        message: "You have already joined this game")
    end

    test "#valid? returns false with name taken and user already joined" do
      existing_user = create(:user)
      game = create(:lq_game, user: existing_user)

      form = NewPlayerForm.new(game:, user: existing_user,
        name: game.guesser.name)

      assert(game.players.any? { |player| player.name == form.name })
      assert game.player_for(existing_user)
      assert_not_predicate form, :valid?
      assert form.errors.added?(:name, message: "has already been taken")
      assert form.errors.added?(:base,
        message: "You have already joined this game")
    end

    test "#valid? normalizes name with NormalizedString" do
      game = create(:lq_game)
      user = create(:user)

      form = NewPlayerForm.new(game:, user:, name: "  Bob  ")

      assert_predicate form, :valid?
      assert_equal "Bob", form.name.to_s
    end

    test "#name returns NormalizedString instance" do
      game = create(:lq_game)
      user = create(:user)
      form = NewPlayerForm.new(game:, user:, name: "Bob")

      assert_instance_of NormalizedString, form.name
    end

    test "#errors returns Errors instance" do
      game = create(:lq_game)
      user = create(:user)
      form = NewPlayerForm.new(game:, user:, name: "Bob")

      assert_instance_of Errors, form.errors
    end
  end
end
