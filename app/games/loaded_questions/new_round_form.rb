# frozen_string_literal: true

module LoadedQuestions
  # Form object for validating new round creation after a round is completed.
  class NewRoundForm
    # @dynamic question, errors
    attr_reader :question, :errors

    def initialize(game:, question: nil)
      @game = game
      question ||= Questions.instance.question
      @question = ::NormalizedString.new(question)
      @errors = Errors.new
    end

    def valid?
      unless game.status.completed?
        errors.add(:game, message: "Game is not completed")
      end

      min = Game::MIN_QUESTION_LENGTH
      max = Game::MAX_QUESTION_LENGTH
      if (error = validate_length(question, min:, max:))
        errors.add(:question, message: error)
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
