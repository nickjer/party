# frozen_string_literal: true

module LoadedQuestions
  class NewPlayerForm
    # @dynamic game
    attr_reader :game

    # @dynamic name
    attr_reader :name

    # @dynamic errors
    attr_reader :errors

    def initialize(game:, params: nil)
      @game = game

      if params
        @name = NormalizedString.new(params[:name])
      else
        @name = NormalizedString.new("")
      end

      @errors = {}
    end

    def game_slug = game.slug

    def valid?
      min = ::Player::MIN_NAME_LENGTH
      max = ::Player::MAX_NAME_LENGTH
      if (error = validate_length(name, min:, max:))
        errors[:name] = error
      end

      if game.players.any? { |player| player.name == name }
        errors[:name] = "has already been taken"
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
