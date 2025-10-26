# frozen_string_literal: true

module LoadedQuestions
  module Broadcast
    # Broadcasts player answer creation to all online players in the game
    class AnswerCreated
      def initialize(game:, player:)
        @game = game
        @player = player
      end

      def call
        PlayerChannel.broadcast_to(game.players) do |current_player|
          ApplicationController.render(
            "loaded_questions/players/answer_created",
            formats: [:turbo_stream],
            locals: { current_player:, player: }
          )
        end
      end

      private

      # @dynamic game, player
      attr_reader :game, :player
    end
  end
end
