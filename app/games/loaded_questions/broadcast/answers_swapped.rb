# frozen_string_literal: true

module LoadedQuestions
  module Broadcast
    # Broadcasts swapped answers to all non-guesser players in the game
    class AnswersSwapped
      def initialize(game:)
        @game = game
      end

      def call
        PlayerChannel.broadcast_to(game.players) do |current_player|
          next if current_player.guesser?

          ApplicationController.render(
            "loaded_questions/games/answers_swapped",
            formats: [:turbo_stream],
            locals: { guessed_answers: game.guesses }
          )
        end
      end

      private

      # @dynamic game
      attr_reader :game
    end
  end
end
