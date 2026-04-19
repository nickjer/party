# frozen_string_literal: true

module BurnUnit
  module Broadcast
    # Broadcasts player name update to all online players in the game
    class PlayerNameUpdated
      def initialize(game:, player:)
        @game = game
        @player = player
      end

      def call
        players = game.players
        PlayerBroadcaster.new(players:).broadcast do |current_player|
          next if current_player.id == player.id

          ApplicationController.render(
            "burn_unit/players/name_updated",
            formats: [:turbo_stream],
            locals: { players:, current_player:, player: }
          )
        end
      end

      private

      # @dynamic game, player
      attr_reader :game, :player
    end
  end
end
