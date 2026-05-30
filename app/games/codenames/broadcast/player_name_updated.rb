# frozen_string_literal: true

module Codenames
  module Broadcast
    # Broadcasts a player's name change to all other online players
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
            "codenames/players/name_updated",
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
