# frozen_string_literal: true

module Codenames
  class Game
    # Immutable value object representing the parsed game document: status,
    # the starting/current teams, the winner, the current clue, and the board.
    class Document
      class << self
        def parse(hash)
          winner = hash.fetch(:winner)
          clue = hash[:clue]
          new(
            status: Status.parse(hash.fetch(:status)),
            starting_team: Team.parse(hash.fetch(:starting_team)),
            current_team: Team.parse(hash.fetch(:current_team)),
            winner: winner ? Team.parse(winner) : nil,
            clue: clue ? Clue.parse(clue) : nil,
            guesses_made: hash[:guesses_made] || 0,
            board: Board.parse(hash.fetch(:board))
          )
        end
      end

      # @dynamic status, starting_team, current_team, winner, clue
      # @dynamic guesses_made, board
      attr_reader :status, :starting_team, :current_team, :winner, :clue,
        :guesses_made, :board

      def initialize(status:, starting_team:, current_team:, winner:, clue:,
        guesses_made:, board:)
        @status = status
        @starting_team = starting_team
        @current_team = current_team
        @winner = winner
        @clue = clue
        @guesses_made = guesses_made
        @board = board
      end

      def with(status: @status, starting_team: @starting_team,
        current_team: @current_team, winner: @winner, clue: @clue,
        guesses_made: @guesses_made, board: @board)
        self.class.new(status:, starting_team:, current_team:, winner:, clue:,
          guesses_made:, board:)
      end

      def to_h
        {
          status: status.to_s,
          starting_team: starting_team.to_s,
          current_team: current_team.to_s,
          winner: winner&.to_s,
          clue: clue&.to_h,
          guesses_made:,
          board: board.to_a
        }
      end

      def to_json(state = nil) = to_h.to_json(state)
    end
  end
end
