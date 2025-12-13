# frozen_string_literal: true

module BurnUnit
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
            "burn_unit/players/create",
            formats: [:turbo_stream],
            locals: { players: game.players, current_player: }
          )
        end
      end

      private

      # @dynamic game, player
      attr_reader :game, :player
    end
  end
end
