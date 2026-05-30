# frozen_string_literal: true

require "test_helper"

module Codenames
  class Game
    class DocumentTest < ActiveSupport::TestCase
      def board = Board.generate(words: Array.new(25) { |i| "W#{i}" },
        starting_team: Team.red)

      def document
        Document.new(status: Status.setup, starting_team: Team.red,
          current_team: Team.red, winner: nil, board:)
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
        assert_equal 25, hash[:board].size
      end

      test ".parse round-trips through to_h" do
        original = document.with(status: Status.completed, winner: Team.blue)

        parsed = Document.parse(original.to_h)

        assert_predicate parsed.status, :completed?
        assert_equal Team.blue, parsed.winner
        assert_equal Team.red, parsed.current_team
        assert_equal 25, parsed.board.cards.size
      end
    end
  end
end
