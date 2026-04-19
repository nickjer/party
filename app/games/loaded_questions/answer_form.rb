# frozen_string_literal: true

module LoadedQuestions
  # Form object for validating player answers during the polling phase.
  class AnswerForm
    # @dynamic answer
    attr_reader :answer

    # @dynamic errors
    attr_reader :errors

    def initialize(answer: nil)
      @answer = Answer.build(value: answer.to_s)
      @errors = Errors.new
    end

    def show? = answer.blank? || !errors.empty?

    def valid?
      if (error = Player::ANSWER_LENGTH.error_for(answer.value))
        errors.add(:answer, message: error)
      end

      errors.empty?
    end
  end
end
