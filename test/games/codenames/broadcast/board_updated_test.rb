# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module Codenames
  module Broadcast
    class BoardUpdatedTest < ActiveSupport::TestCase
      include Turbo::Broadcastable::TestHelper

      def online_game
        game = create(:cn_playing_game)
        game.players.each do |player|
          PlayerConnections.instance.increment(player.id)
        end
        game
      end

      test "#call broadcasts to other online players" do
        game = online_game
        actor = game.players.find { |player| player.name.to_s == "RedOp" }
        other = game.players.find { |player| player.name.to_s == "BlueOp" }

        assert_turbo_stream_broadcasts other, count: 1 do
          BoardUpdated.new(game:, player: actor).call
        end
      end

      test "#call does not broadcast to the acting player" do
        game = online_game
        actor = game.players.find { |player| player.name.to_s == "RedOp" }

        assert_turbo_stream_broadcasts actor, count: 0 do
          BoardUpdated.new(game:, player: actor).call
        end
      end

      test "#call updates the play_area target" do
        game = online_game
        actor = game.players.find { |player| player.name.to_s == "RedOp" }
        spy = game.players.find { |player| player.name.to_s == "BlueSpy" }

        streams = capture_turbo_stream_broadcasts spy do
          BoardUpdated.new(game:, player: actor).call
        end

        assert_equal "update", streams[0]["action"]
        assert_equal "play_area", streams[0]["target"]
      end

      test "#call swaps the frame for a teamless joiner when the game ends" do
        game = online_game
        latecomer = game.add_player(
          user_id: create(:user).id, name: PlayerName.parse("Late")
        )
        PlayerConnections.instance.increment(latecomer.id)
        assassin = game.board.cards.index { |card| card.identity.assassin? }
        game.reveal(index: assassin)
        assert_predicate game.status, :completed?

        actor = game.players.find { |player| player.name.to_s == "RedOp" }
        streams = capture_turbo_stream_broadcasts latecomer do
          BoardUpdated.new(game:, player: actor).call
        end

        assert_equal "update", streams[0]["action"]
        assert_equal "game_frame", streams[0]["target"]
      end
    end
  end
end
