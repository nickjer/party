# frozen_string_literal: true

module LoadedQuestions
  module Broadcast
    # Broadcasts swapped answers to all non-guesser players in the game
    class AnswersSwapped
      def initialize(game_id:)
        @game_id = game_id
      end

      def call
        game = Game.from_id(game_id)

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

      # @dynamic game_id
      attr_reader :game_id
    end
  end
end
