# frozen_string_literal: true

module LoadedQuestions
  class Player
    # Immutable value object representing the parsed player document. Owns
    # the non-negative-score invariant. Answer length is not validated here
    # since the empty answer is a legitimate sentinel for "has not answered
    # yet"; the wrapper's `answer=` setter validates real submissions.
    class Document
      # @dynamic answer, guesser, score
      attr_reader :answer, :guesser, :score

      def initialize(answer:, guesser:, score:)
        raise ArgumentError, "Score cannot be negative" if score.negative?

        @answer = answer
        @guesser = guesser
        @score = score
      end

      class << self
        def parse(hash)
          new(
            answer: Answer.parse(hash.fetch(:answer)),
            guesser: hash.fetch(:guesser),
            score: hash.fetch(:score)
          )
        end
      end

      def with(answer: @answer, guesser: @guesser, score: @score)
        self.class.new(answer:, guesser:, score:)
      end

      def as_json
        { answer:, guesser:, score: }.as_json
      end
    end
  end
end
