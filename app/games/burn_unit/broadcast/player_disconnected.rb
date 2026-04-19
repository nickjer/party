# frozen_string_literal: true

module BurnUnit
  module Broadcast
    # Broadcasts player disconnection status to all online players in the game
    class PlayerDisconnected
      def initialize(player_id:)
        @disconnected_player = ::Player.find(player_id)
      end

      def call
        game = Game.find(disconnected_player.game_id)
        player = game.find_player(disconnected_player.id)
        players = game.players

        PlayerBroadcaster.new(players:).broadcast do |current_player|
          next if current_player.id == player.id

          ApplicationController.render(
            "burn_unit/players/disconnected",
            formats: [:turbo_stream],
            locals: { current_player:, player: }
          )
        end
      end

      private

      # @dynamic disconnected_player
      attr_reader :disconnected_player
    end
  end
end
