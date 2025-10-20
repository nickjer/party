# frozen_string_literal: true

module LoadedQuestions
  module Broadcast
    # Broadcasts player name update to all online players in the game
    class PlayerNameUpdated
      def initialize(player_id:)
        @updated_player = ::Player.find(player_id)
      end

      def call
        game = Game.from_id(updated_player.game_id)

        PlayerChannel.broadcast_to(game.players) do |current_player|
          ApplicationController.render(
            "loaded_questions/players/name_updated",
            formats: [:turbo_stream],
            locals: { game:, current_player: }
          )
        end
      end

      private

      # @dynamic updated_player
      attr_reader :updated_player
    end
  end
end
