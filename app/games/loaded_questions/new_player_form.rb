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
      if (error = ::PlayerName::LENGTH.error_for(name))
        errors.add(:name, message: error)
      else
        player_name = ::PlayerName.new(name)
        ::PlayerNameValidator.new(game:, name: player_name).apply_to(errors)
      end
      ::UniquePlayerValidator.new(game:, user_id:).apply_to(errors)
      errors.empty?
    end
  end
end
