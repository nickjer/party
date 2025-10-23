# frozen_string_literal: true

module LoadedQuestions
  module Broadcast
    # Broadcasts guessing round start to all non-guesser players in the game
    class GuessingRoundStarted
      def initialize(game:)
        @game = game
      end

      def call
        PlayerChannel.broadcast_to(game.players) do |current_player|
          next if current_player.guesser?

          ApplicationController.render(
            "loaded_questions/games/guessing_round_started",
            formats: [:turbo_stream],
            locals: { game: }
          )
        end
      end

      private

      # @dynamic game
      attr_reader :game
    end
  end
end
