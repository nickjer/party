# frozen_string_literal: true

module LoadedQuestions
  # Form object for validating new player creation with unique name validation.
  class NewPlayerForm
    # @dynamic game
    attr_reader :game

    # @dynamic name
    attr_reader :name

    # @dynamic errors
    attr_reader :errors

    def initialize(game:, name: nil)
      @game = game
      @name = NormalizedString.new(name)
      @errors = {}
    end

    def game_slug = game.slug

    def valid?
      min = ::Player::MIN_NAME_LENGTH
      max = ::Player::MAX_NAME_LENGTH
      if (error = validate_length(name, min:, max:))
        errors[:name] = error
      end

      errors[:name] = "has already been taken" if game.players.any? { |player| player.name == name }

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
