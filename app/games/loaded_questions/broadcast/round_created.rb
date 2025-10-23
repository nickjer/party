# frozen_string_literal: true

module LoadedQuestions
  module Broadcast
    # Broadcasts new round creation to all non-guesser players in the game
    class RoundCreated
      def initialize(game:)
        @game = game
      end

      def call
        PlayerChannel.broadcast_to(game.players) do |current_player|
          next if current_player.guesser?

          ApplicationController.render(
            "loaded_questions/games/round_created",
            formats: [:turbo_stream],
            locals: { game:, current_player:, answer_form: AnswerForm.new }
          )
        end
      end

      private

      # @dynamic game
      attr_reader :game
    end
  end
end
