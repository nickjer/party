# frozen_string_literal: true

module LoadedQuestions
  class NewRoundForm
    # @dynamic question, errors
    attr_reader :question, :errors

    def initialize(game:, question: nil)
      @game = game
      @question = ::NormalizedString.new(question)
      @errors = {}
    end

    def valid?
      errors[:game] = "Game is not completed" unless game.status.completed?

      min = ::Game::MIN_QUESTION_LENGTH
      max = ::Game::MAX_QUESTION_LENGTH
      if (error = validate_length(question, min:, max:))
        errors[:question] = error
      end

      errors.empty?
    end

    private

    # @dynamic game
    attr_reader :game

    def validate_length(value, min:, max:)
      if value.length < min
        "is too short (minimum is #{min} characters)"
      elsif value.length > max
        "is too long (maximum is #{max} characters)"
      end
    end
  end
end
