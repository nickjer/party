# frozen_string_literal: true

require "test_helper"

class UniquePlayerValidatorTest < ActiveSupport::TestCase
  test "#apply_to is silent when user has not joined the game" do
    game = build(:lq_polling_game)
    errors = Errors.new

    UniquePlayerValidator.new(game:, user_id: "unknown").apply_to(errors)

    assert_predicate errors, :empty?
  end

  test "#apply_to adds base error when user has already joined" do
    game = build(:lq_polling_game)
    existing_player = game.players.first
    errors = Errors.new

    UniquePlayerValidator.new(
      game:, user_id: existing_player.user_id
    ).apply_to(errors)

    assert errors.added?(:base, message: "You have already joined this game")
  end
end
