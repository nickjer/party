# frozen_string_literal: true

# Validates player name updates. Game-agnostic; shared across all game kinds.
class EditPlayerForm
  # @dynamic game
  attr_reader :game

  # @dynamic current_player
  attr_reader :current_player

  # @dynamic name
  attr_reader :name

  # @dynamic player_name
  attr_reader :player_name

  # @dynamic errors
  attr_reader :errors

  def initialize(game:, current_player:, name: nil)
    @game = game
    @current_player = current_player
    @name = NameEasterEgg.new(name || current_player.name).apply
    @errors = Errors.new
  end

  def valid?
    @player_name = ::PlayerName.build(name, errors:)
    if player_name
      ::PlayerNameValidator.new(
        game:, name: player_name, current_name: current_player.name
      ).apply_to(errors)
    end
    errors.empty?
  end
end
