# frozen_string_literal: true

module BurnUnit
  class Game
    # Immutable value object representing the parsed game document. Owns the
    # question-length invariant: every construction path (direct, `with`, or
    # `parse`) goes through `initialize` and rejects invalid input.
    class Document
      # @dynamic question, status
      attr_reader :question, :status

      def initialize(question:, status:)
        QUESTION_LENGTH.validate!(question)

        @question = question
        @status = status
      end

      class << self
        def parse(hash)
          new(
            question: ::NormalizedString.new(hash.fetch(:question)),
            status: Status.parse(hash.fetch(:status))
          )
        end
      end

      def with(question: @question, status: @status)
        self.class.new(question:, status:)
      end

      def to_h
        { question: question.to_s, status: status.to_s }
      end

      def to_json(state = nil) = to_h.to_json(state)
    end
  end
end
