# frozen_string_literal: true

module Wavelength
  module Broadcast
    # Broadcasts the live dial position to every other online player so the
    # shared dial tracks in real time. Only the marker element is updated.
    class DialMoved
      def initialize(game:, player:)
        @game = game
        @player = player
      end

      def call
        players = game.players
        PlayerBroadcaster.new(players:).broadcast do |current_player|
          next if current_player.id == player.id

          ApplicationController.render(
            "wavelength/games/dial_moved",
            formats: [:turbo_stream],
            locals: { game: }
          )
        end
      end

      private

      # @dynamic game, player
      attr_reader :game, :player
    end
  end
end
