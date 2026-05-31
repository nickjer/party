# frozen_string_literal: true

module Codenames
  module Broadcast
    # Broadcasts a fresh game (board regenerated, back to lobby) to all other
    # online players.
    class NewGameStarted
      def initialize(game:, player:)
        @game = game
        @player = player
      end

      def call
        players = game.players
        PlayerBroadcaster.new(players:).broadcast do |current_player|
          next if current_player.id == player.id

          ApplicationController.render(
            "codenames/games/new_game_started",
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
