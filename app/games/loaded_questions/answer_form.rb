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
      min = Player::MIN_ANSWER_LENGTH
      max = Player::MAX_ANSWER_LENGTH
      if (error = validate_length(answer.value, min:, max:))
        errors.add(:answer, message: error)
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
