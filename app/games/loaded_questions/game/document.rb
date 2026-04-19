# frozen_string_literal: true

module LoadedQuestions
  class Game
    # Immutable value object representing the parsed game document. Owns the
    # question-length invariant: every construction path (direct, `with`, or
    # `parse`) goes through `initialize` and rejects invalid input.
    class Document
      # @dynamic question, status, guesses_data
      attr_reader :question, :status, :guesses_data

      def initialize(question:, status:, guesses_data:)
        QUESTION_LENGTH.validate!(question)

        @question = question
        @status = status
        @guesses_data = guesses_data
      end

      class << self
        def parse(hash)
          new(
            question: ::NormalizedString.new(hash.fetch(:question)),
            status: Status.parse(hash.fetch(:status)),
            guesses_data: hash.fetch(:guesses)
          )
        end
      end

      def with(
        question: @question,
        status: @status,
        guesses_data: @guesses_data
      )
        self.class.new(question:, status:, guesses_data:)
      end

      def to_h
        {
          question: question.to_s,
          status: status.to_s,
          guesses: guesses_data
        }
      end

      def to_json(state = nil) = to_h.to_json(state)
    end
  end
end
