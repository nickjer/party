# frozen_string_literal: true

require "test_helper"

module Codenames
  class Game
    class DocumentTest < ActiveSupport::TestCase
      test ".parse round-trips through to_h" do
        original = document.with(status: Status.completed, winner: Team.blue)

        parsed = Document.parse(original.to_h)

        assert_predicate parsed.status, :completed?
        assert_equal Team.blue, parsed.winner
        assert_equal Team.red, parsed.current_team
        assert_equal 25, parsed.board.cards.size
      end

      test ".parse round-trips a clue and guess count" do
        clue = Clue.new(word: NormalizedString.new("Ocean"), number: 2)
        original = document.with(clue:, guesses_made: 1)

        parsed = Document.parse(original.to_h)

        assert_equal clue, parsed.clue
        assert_equal 1, parsed.guesses_made
      end

      test ".parse defaults clue and guess count for pre-clue documents" do
        hash = document.to_h.except(:clue, :guesses_made)

        parsed = Document.parse(hash)

        assert_nil parsed.clue
        assert_equal 0, parsed.guesses_made
      end

      test "#with swaps in new values and keeps the rest" do
        updated = document.with(status: Status.playing)

        assert_predicate updated.status, :playing?
        assert_equal Team.red, updated.starting_team
      end

      test "#to_h serializes scalars and the board" do
        hash = document.to_h

        assert_equal "setup", hash[:status]
        assert_equal "red", hash[:starting_team]
        assert_equal "red", hash[:current_team]
        assert_nil hash[:winner]
        assert_nil hash[:clue]
        assert_equal 0, hash[:guesses_made]
        assert_equal 25, hash[:board].size
      end

      private

      def board
        Board.generate(words: Array.new(25) { |i| "W#{i}" },
          starting_team: Team.red)
      end

      def document
        Document.new(status: Status.setup, starting_team: Team.red,
          current_team: Team.red, winner: nil, clue: nil, guesses_made: 0,
          board:)
      end
    end
  end
end
