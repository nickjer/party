# frozen_string_literal: true

module BurnUnit
  class Player
    # Immutable value object representing the parsed player document. Owns
    # the non-negative-score invariant.
    class Document
      # @dynamic judge, score, vote, playing
      attr_reader :judge, :score, :vote, :playing

      def initialize(judge:, score:, vote:, playing:)
        raise ArgumentError, "Score cannot be negative" if score.negative?

        @judge = judge
        @score = score
        @vote = vote
        @playing = playing
      end

      class << self
        def parse(hash)
          new(
            judge: hash.fetch(:judge),
            score: hash.fetch(:score),
            vote: hash.fetch(:vote),
            playing: hash.fetch(:playing)
          )
        end
      end

      def with(judge: @judge, score: @score, vote: @vote, playing: @playing)
        self.class.new(judge:, score:, vote:, playing:)
      end

      def to_h = { judge:, score:, vote:, playing: }

      def to_json(state = nil) = to_h.to_json(state)
    end
  end
end
