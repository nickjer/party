# frozen_string_literal: true

module BurnUnit
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
      if (error = ::Player::NAME_LENGTH.error_for(name))
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
  end
end
