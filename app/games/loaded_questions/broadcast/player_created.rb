# frozen_string_literal: true

module LoadedQuestions
  module Broadcast
    # Broadcasts player creation to all other online players in the game
    class PlayerCreated
      def initialize(game:, player:)
        @game = game
        @player = player
      end

      def call
        PlayerChannel.broadcast_to(game.players) do |current_player|
          next if current_player.id == player.id

          ApplicationController.render(
            "loaded_questions/players/create",
            formats: [:turbo_stream],
            locals: { game:, current_player: }
          )
        end
      end

      private

      # @dynamic game, player
      attr_reader :game, :player
    end
  end
end
