# frozen_string_literal: true

module Codenames
  class Game
    # Immutable value object wrapping the 25 cards in their 5x5 layout
    # (position is the array index). Owns the agent counts and reveal state.
    class Board
      SIZE = 25

      class << self
        def generate(words:, starting_team:)
          unless words.size >= SIZE
            raise(ArgumentError, "Need at least #{SIZE} words")
          end

          identities = build_identities(starting_team).shuffle
          cards = words.first(SIZE).map.with_index do |word, index|
            Card.new(word:, identity: identities.fetch(index), revealed: false)
          end
          new(cards:)
        end

        def parse(board)
          new(cards: board.map { |card| Card.parse(card) })
        end

        private

        def build_identities(starting_team)
          [
            *Array.new(9) { Identity.agent(starting_team) },
            *Array.new(8) { Identity.agent(starting_team.opponent) },
            *Array.new(7) { Identity.bystander },
            Identity.assassin
          ]
        end
      end

      # @dynamic cards
      attr_reader :cards

      def initialize(cards:) = @cards = cards

      def all_revealed?(team) = remaining(team).zero?

      def card(index) = cards.fetch(index)

      def remaining(team) = total_for(team) - revealed_count(team)

      def reveal(index)
        new_cards = cards.map.with_index do |card, position|
          position == index ? card.reveal : card
        end
        self.class.new(cards: new_cards)
      end

      def revealed_count(team)
        cards.count { |card| card.identity.team == team && card.revealed? }
      end

      def total_for(team)
        cards.count { |card| card.identity.team == team }
      end

      def to_a = cards.map(&:to_h)
    end
  end
end
