# frozen_string_literal: true

module LoadedQuestions
  # Form object for validating new game creation with player name and question.
  class NewGameForm
    # @dynamic player_name
    attr_reader :player_name

    # @dynamic question
    attr_reader :question

    # @dynamic errors
    attr_reader :errors

    def initialize(player_name: nil, question: nil)
      @player_name = ::NormalizedString.new(player_name)
      @question = ::NormalizedString.new(question)
      @errors = Errors.new
    end

    def valid?
      min = ::Player::MIN_NAME_LENGTH
      max = ::Player::MAX_NAME_LENGTH
      if (error = validate_length(player_name, min:, max:))
        errors.add(:player_name, message: error)
      end

      min = ::Game::MIN_QUESTION_LENGTH
      max = ::Game::MAX_QUESTION_LENGTH
      if (error = validate_length(question, min:, max:))
        errors.add(:question, message: error)
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
