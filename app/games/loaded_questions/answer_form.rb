# frozen_string_literal: true

module LoadedQuestions
  class AnswerForm
    MIN_LENGTH = 3
    MAX_LENGTH = 80

    # @dynamic answer
    attr_reader :answer

    # @dynamic errors
    attr_reader :errors

    def initialize(answer: nil)
      @answer = ::NormalizedString.new(answer)
      @errors = {}
    end

    def show? = answer.blank? || !errors.empty?

    def valid?
      min = MIN_LENGTH
      max = MAX_LENGTH
      if (error = validate_length(answer, min:, max:))
        errors[:answer] = error
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
