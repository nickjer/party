# frozen_string_literal: true

module LoadedQuestions
  module Broadcast
    # Broadcasts player disconnection status to all online players in the game
    class PlayerDisconnected
      def initialize(player_id:)
        @disconnected_player = ::Player.find(player_id)
      end

      def call
        game = Game.from_id(disconnected_player.game_id)
        player = game.find_player(disconnected_player.id)

        PlayerChannel.broadcast_to(game.players) do |current_player|
          ApplicationController.render(
            "loaded_questions/players/disconnected",
            formats: [:turbo_stream],
            assigns: { current_player:, player: }
          )
        end
      end

      private

      # @dynamic disconnected_player
      attr_reader :disconnected_player
    end
  end
end
