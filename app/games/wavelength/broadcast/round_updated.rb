# frozen_string_literal: true

module Wavelength
  module Broadcast
    # Broadcasts any in-round change (lock, reveal, next round) to all other
    # online players. Each recipient re-renders their own play_area variant.
    class RoundUpdated
      def initialize(game:, player:)
        @game = game
        @player = player
      end

      def call
        players = game.players
        PlayerBroadcaster.new(players:).broadcast do |current_player|
          next if current_player.id == player.id

          ApplicationController.render(
            "wavelength/games/round_updated",
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
