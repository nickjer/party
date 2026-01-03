# frozen_string_literal: true

module LoadedQuestions
  module Broadcast
    # Broadcasts updated guesses to all non-guesser players in the game
    class GuessesUpdated
      def initialize(game:)
        @game = game
      end

      def call
        PlayerChannel.broadcast_to(game.players) do |current_player|
          next if current_player.guesser?

          ApplicationController.render(
            "loaded_questions/games/guesses_updated",
            formats: [:turbo_stream],
            locals: { guesses: game.guesses }
          )
        end
      end

      private

      # @dynamic game
      attr_reader :game
    end
  end
end
