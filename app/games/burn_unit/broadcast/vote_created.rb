# frozen_string_literal: true

module BurnUnit
  module Broadcast
    # Broadcasts player vote creation to all online players in the game
    class VoteCreated
      def initialize(game:, player:)
        @game = game
        @player = player
      end

      def call
        PlayerChannel.broadcast_to(game.players) do |current_player|
          ApplicationController.render(
            "burn_unit/players/vote_created",
            formats: [:turbo_stream],
            locals: { current_player:, player: }
          )
        end
      end

      private

      # @dynamic game, player
      attr_reader :game, :player
    end
  end
end
