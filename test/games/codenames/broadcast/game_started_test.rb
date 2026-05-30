# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module Codenames
  module Broadcast
    class GameStartedTest < ActiveSupport::TestCase
      include Turbo::Broadcastable::TestHelper

      test "#call broadcasts the board to other online players" do
        game = create(:cn_playing_game)
        game.players.each { |player| PlayerConnections.instance.increment(player.id) }
        actor = game.spymaster_for(Team.red)
        other = game.players.find { |player| player.name.to_s == "BlueOp" }

        streams = capture_turbo_stream_broadcasts other do
          GameStarted.new(game:, player: actor).call
        end

        assert_equal 1, streams.size
        assert_equal "game_frame", streams[0]["target"]
      end

      test "#call does not broadcast to the acting player" do
        game = create(:cn_playing_game)
        actor = game.spymaster_for(Team.red)
        PlayerConnections.instance.increment(actor.id)

        assert_turbo_stream_broadcasts actor, count: 0 do
          GameStarted.new(game:, player: actor).call
        end
      end
    end
  end
end
