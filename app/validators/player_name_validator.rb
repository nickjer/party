# frozen_string_literal: true

# Checks a PlayerName is not already taken by another player in the game.
# Pass `current_name:` on a rename so a no-op rename doesn't self-collide.
class PlayerNameValidator
  def initialize(game:, name:, current_name: nil)
    @game = game
    @name = name
    @current_name = current_name
  end

  def apply_to(errors)
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
