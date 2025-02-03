# frozen_string_literal: true

module LoadedQuestions
  class NewPlayerForm
    # @dynamic game
    attr_reader :game

    # @dynamic player_name
    attr_reader :player_name

    # @dynamic errors
    attr_reader :errors

    def initialize(game:, params: nil)
      if params
        @player_name = NormalizedString.new(params[:player_name])
      else
        @player_name = NormalizedString.new("")
      end

      @errors = {}
    end

    def valid?
      min = ::Player::MIN_NAME_LENGTH
      max = ::Player::MAX_NAME_LENGTH
      if (error = validate_length(player_name, min:, max:))
        errors[:player_name] = error
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
