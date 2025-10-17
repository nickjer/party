# frozen_string_literal: true

module LoadedQuestions
  module Broadcast
    # Broadcasts player creation to all other online players in the game
    class PlayerCreated
      def initialize(player_id:)
        @created_player = ::Player.find(player_id)
      end

      def call
        game = Game.from_id(created_player.game_id)

        PlayerChannel.broadcast_to(game.players) do |current_player|
          next if current_player.id == created_player.id

          ApplicationController.render(
            "loaded_questions/players/create",
            formats: [:turbo_stream],
            assigns: { game:, current_player: }
          )
        end
      end

      private

      # @dynamic created_player
      attr_reader :created_player
    end
  end
end
