# frozen_string_literal: true

require "test_helper"

class PlayerNameValidatorTest < ActiveSupport::TestCase
  test "#apply_to adds length error when name too short" do
    game = build(:lq_polling_game, player_names: %w[Bob])
    name = NormalizedString.new("ab")
    errors = Errors.new

    PlayerNameValidator.new(game:, name:).apply_to(errors)

    assert errors.added?(:name,
      message: "is too short (minimum is 3 characters)")
  end

  test "#apply_to adds length error when name too long" do
    game = build(:lq_polling_game, player_names: %w[Bob])
    name = NormalizedString.new("a" * 26)
    errors = Errors.new

    PlayerNameValidator.new(game:, name:).apply_to(errors)

    assert errors.added?(:name,
      message: "is too long (maximum is 25 characters)")
  end

  test "#apply_to adds taken error when name matches another player" do
    game = build(:lq_polling_game, player_names: %w[Bob])
    name = NormalizedString.new("Bob")
    errors = Errors.new

    PlayerNameValidator.new(game:, name:).apply_to(errors)

    assert errors.added?(:name, message: "has already been taken")
  end

  test "#apply_to matches names case-insensitively" do
    game = build(:lq_polling_game, player_names: %w[Bob])
    name = NormalizedString.new("bob")
    errors = Errors.new

    PlayerNameValidator.new(game:, name:).apply_to(errors)

    assert errors.added?(:name, message: "has already been taken")
  end

  test "#apply_to is silent when name is unique and valid" do
    game = build(:lq_polling_game, player_names: %w[Bob])
    name = NormalizedString.new("Alice")
    errors = Errors.new

    PlayerNameValidator.new(game:, name:).apply_to(errors)

    assert_predicate errors, :empty?
  end

  test "#apply_to skips uniqueness when name equals current_name" do
    game = build(:lq_polling_game, player_names: %w[Alice])
    current_name = NormalizedString.new("Alice")
    name = NormalizedString.new("Alice")
    errors = Errors.new

    PlayerNameValidator.new(game:, name:, current_name:).apply_to(errors)

    assert_predicate errors, :empty?
  end

  test "#apply_to skips uniqueness when name normalizes equal to " \
    "current_name" do
    game = build(:lq_polling_game, player_names: %w[Alice])
    current_name = NormalizedString.new("Alice")
    name = NormalizedString.new("alice")
    errors = Errors.new

    PlayerNameValidator.new(game:, name:, current_name:).apply_to(errors)

    assert_predicate errors, :empty?
  end

  test "#apply_to still runs length check when name equals current_name" do
    game = build(:lq_polling_game, player_names: %w[Bob])
    current_name = NormalizedString.new("ab")
    name = NormalizedString.new("ab")
    errors = Errors.new

    PlayerNameValidator.new(game:, name:, current_name:).apply_to(errors)

    assert errors.added?(:name,
      message: "is too short (minimum is 3 characters)")
  end

  test "#apply_to adds taken error when renaming to another " \
    "player's name" do
    game = build(:lq_polling_game, player_names: %w[Alice Bob])
    current_name = NormalizedString.new("Alice")
    name = NormalizedString.new("Bob")
    errors = Errors.new

    PlayerNameValidator.new(game:, name:, current_name:).apply_to(errors)

    assert errors.added?(:name, message: "has already been taken")
  end
end
