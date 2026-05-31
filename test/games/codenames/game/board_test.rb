# frozen_string_literal: true

require "test_helper"

module Codenames
  class Game
    class BoardTest < ActiveSupport::TestCase
      def words = Array.new(25) { |index| "WORD#{index}" }

      test ".generate lays out 25 cards" do
        board = Board.generate(words:, starting_team: Team.red)

        assert_equal 25, board.cards.size
      end

      test ".generate gives the starting team 9 agents and the other 8" do
        board = Board.generate(words:, starting_team: Team.red)

        assert_equal 9, board.total_for(Team.red)
        assert_equal 8, board.total_for(Team.blue)
      end

      test ".generate includes 7 bystanders and 1 assassin" do
        board = Board.generate(words:, starting_team: Team.blue)

        assert_equal(7, board.cards.count { |card| card.identity.bystander? })
        assert_equal(1, board.cards.count { |card| card.identity.assassin? })
      end

      test ".generate gives blue 9 when blue starts" do
        board = Board.generate(words:, starting_team: Team.blue)

        assert_equal 9, board.total_for(Team.blue)
        assert_equal 8, board.total_for(Team.red)
      end

      test ".generate uses the supplied words" do
        board = Board.generate(words:, starting_team: Team.red)

        assert_equal words.sort, board.cards.map(&:word).sort
      end

      test ".generate raises with too few words" do
        assert_raises(ArgumentError) do
          Board.generate(words: %w[a b c], starting_team: Team.red)
        end
      end

      test "#reveal returns a new board with the card revealed" do
        board = Board.generate(words:, starting_team: Team.red)

        revealed = board.reveal(0)

        assert_predicate revealed.card(0), :revealed?
        assert_not_predicate board.card(0), :revealed?
      end

      test "#remaining counts unrevealed agents for the team" do
        board = Board.generate(words:, starting_team: Team.red)
        red_index = board.cards.index { |card| card.identity.team == Team.red }

        revealed = board.reveal(red_index)

        assert_equal 8, revealed.remaining(Team.red)
      end

      test "#all_revealed? is true once every agent is revealed" do
        board = Board.generate(words:, starting_team: Team.red)
        board.cards.each_with_index do |card, index|
          board = board.reveal(index) if card.identity.team == Team.red
        end

        assert board.all_revealed?(Team.red)
        assert_not board.all_revealed?(Team.blue)
      end

      test ".parse round-trips through to_a" do
        board = Board.generate(words:, starting_team: Team.red)

        parsed = Board.parse(board.to_a)

        assert_equal board.cards.map(&:word), parsed.cards.map(&:word)
        assert_equal 9, parsed.total_for(Team.red)
      end
    end
  end
end
