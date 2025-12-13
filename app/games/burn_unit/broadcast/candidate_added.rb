# frozen_string_literal: true

module BurnUnit
  module Broadcast
    # Broadcasts when a player becomes a candidate to all online players
    class CandidateAdded
      def initialize(game:, player:)
        @game = game
        @player = player
      end

      def call
        PlayerChannel.broadcast_to(game.players) do |current_player|
          next if current_player.id == player.id

          ApplicationController.render(
            "burn_unit/players/candidate_added",
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
