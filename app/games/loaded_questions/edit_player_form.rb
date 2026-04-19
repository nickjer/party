# frozen_string_literal: true

module LoadedQuestions
  # Form object for validating player name updates with unique name validation.
  class EditPlayerForm
    # @dynamic game
    attr_reader :game

    # @dynamic current_player
    attr_reader :current_player

    # @dynamic name
    attr_reader :name

    # @dynamic errors
    attr_reader :errors

    def initialize(game:, current_player:, name: nil)
      @game = game
      @current_player = current_player
      @name = NormalizedString.new(name || current_player.name)
      @errors = Errors.new
    end

    def valid?
      ::PlayerNameValidator.new(
        game:, name:, current_name: current_player.name
      ).apply_to(errors)
      errors.empty?
    end
  end
end
