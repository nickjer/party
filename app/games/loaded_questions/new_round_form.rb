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

      if (error = Game::QUESTION_LENGTH.error_for(question))
        errors.add(:question, message: error)
      end

      errors.empty?
    end

    private

    # @dynamic game
    attr_reader :game
  end
end
