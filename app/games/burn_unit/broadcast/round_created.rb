# frozen_string_literal: true

module BurnUnit
  module Broadcast
    # Broadcasts new round creation to all non-judge players in the game
    class RoundCreated
      def initialize(game:)
        @game = game
      end

      def call
        PlayerChannel.broadcast_to(game.players) do |current_player|
          next if current_player.judge?

          ApplicationController.render(
            "burn_unit/games/round_created",
            formats: [:turbo_stream],
            locals: { game:, current_player:, vote_form: VoteForm.new(game:,
              current_player:) }
          )
        end
      end

      private

      # @dynamic game
      attr_reader :game
    end
  end
end
