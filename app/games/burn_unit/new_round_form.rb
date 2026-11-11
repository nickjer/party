# frozen_string_literal: true

module BurnUnit
  # Input check for opening the next round: the question's length. Status and
  # role are the aggregate's concern.
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
