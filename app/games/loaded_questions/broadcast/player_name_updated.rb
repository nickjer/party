# frozen_string_literal: true

module LoadedQuestions
  module Broadcast
    # Broadcasts player name update to all online players in the game
    class PlayerNameUpdated
      def initialize(game:, player:)
        @game = game
        @player = player
      end

      def call
        PlayerChannel.broadcast_to(game.players) do |current_player|
          next if current_player.id == player.id

          ApplicationController.render(
            "loaded_questions/players/name_updated",
            formats: [:turbo_stream],
            locals: { players: game.players, current_player:, player: }
          )
        end
      end

      private

      # @dynamic game, player
      attr_reader :game, :player
    end
  end
end
