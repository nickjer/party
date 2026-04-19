# frozen_string_literal: true

# Validates a player name's length and uniqueness within a game. Pass
# `current_name:` when validating a rename so a no-op rename (or a
# normalized-equal variant of the current name) doesn't trigger a
# self-collision.
class PlayerNameValidator
  def initialize(game:, name:, current_name: nil)
    @game = game
    @name = name
    @current_name = current_name
  end

  def apply_to(errors)
    if (error = ::Player::NAME_LENGTH.error_for(name))
      errors.add(:name, message: error)
    end

    errors.add(:name, message: "has already been taken") if name_taken?
  end

  private

  # @dynamic game, name, current_name
  attr_reader :game, :name, :current_name

  def name_taken?
    return false if current_name && name == current_name

    game.players.any? { |player| player.name == name }
  end
end
