# frozen_string_literal: true

module LoadedQuestions
  module Broadcast
    # Broadcasts player connection status to all online players in the game
    class PlayerConnected
      def initialize(player_id:)
        @connected_player = ::Player.find(player_id)
      end

      def call
        game = Game.find(connected_player.game_id)
        player = game.find_player(connected_player.id)

        PlayerChannel.broadcast_to(game.players) do |current_player|
          next if current_player.id == player.id

          ApplicationController.render(
            "loaded_questions/players/connected",
            formats: [:turbo_stream],
            locals: { current_player:, player: }
          )
        end
      end

      private

      # @dynamic connected_player
      attr_reader :connected_player
    end
  end
end
