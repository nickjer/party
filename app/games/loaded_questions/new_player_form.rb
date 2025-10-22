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

    # @dynamic user_id
    attr_reader :user_id

    def initialize(game:, user_id:, name: nil)
      @game = game
      @user_id = user_id
      @name = NormalizedString.new(name)
      @errors = Errors.new
    end

    def valid?
      min = ::Player::MIN_NAME_LENGTH
      max = ::Player::MAX_NAME_LENGTH
      if (error = validate_length(name, min:, max:))
        errors.add(:name, message: error)
      end

      if game.players.any? { |player| player.name == name }
        errors.add(:name, message: "has already been taken")
      end

      if game.player_for(user_id)
        errors.add(:base, message: "You have already joined this game")
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
