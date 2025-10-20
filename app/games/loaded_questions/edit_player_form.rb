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
      min = ::Player::MIN_NAME_LENGTH
      max = ::Player::MAX_NAME_LENGTH
      if (error = validate_length(name, min:, max:))
        errors.add(:name, message: error)
      end

      other_players = game.players.reject { |player| player == current_player }
      if other_players.any? { |player| player.name == name }
        errors.add(:name, message: "has already been taken")
      end

      errors.empty?
    end

    private

    def validate_length(value, min:, max:)
      if value.length < min
        "is too short (minimum is #{min} characters)"
      elsif value.length > max
        "is too long (maximum is #{max} characters)"
      end
    end
  end
end
