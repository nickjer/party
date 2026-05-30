# frozen_string_literal: true

module Codenames
  module Broadcast
    # Broadcasts a board/turn change (reveal, pass, or win) to all other
    # online players. Each recipient gets their spymaster/operative variant.
    class BoardUpdated
      def initialize(game:, player:)
        @game = game
        @player = player
      end

      def call
        players = game.players
        PlayerBroadcaster.new(players:).broadcast do |current_player|
          next if current_player.id == player.id

          ApplicationController.render(
            "codenames/games/board_updated",
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
