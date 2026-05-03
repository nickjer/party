# frozen_string_literal: true

module BurnUnit
  # Form object for validating player name updates with unique name validation.
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
      @name = NormalizedString.new(name || current_player.name)
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
end
