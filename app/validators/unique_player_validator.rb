# frozen_string_literal: true

# Validates that a given user is not already a player in the game.
# Enforces the "one player per user per game" invariant for join forms.
class UniquePlayerValidator
  def initialize(game:, user_id:)
    @game = game
    @user_id = user_id
  end

  def apply_to(errors)
    return unless game.player_for(user_id)

    errors.add(:base, message: "You have already joined this game")
  end

  private

  # @dynamic game, user_id
  attr_reader :game, :user_id
end
