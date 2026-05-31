# frozen_string_literal: true

module Codenames
  class Game
    # Immutable value object for a single board card: its word, secret
    # identity, and whether it has been revealed.
    class Card
      class << self
        def parse(hash)
          new(
            word: hash.fetch(:word),
            identity: Identity.parse(hash.fetch(:identity)),
            revealed: hash.fetch(:revealed)
          )
        end
      end

      # @dynamic word, identity
      attr_reader :word, :identity

      def initialize(word:, identity:, revealed:)
        @word = word
        @identity = identity
        @revealed = revealed
      end

      def revealed? = @revealed

      def reveal = self.class.new(word:, identity:, revealed: true)

      def to_h = { word:, identity: identity.to_s, revealed: @revealed }
    end
  end
end
