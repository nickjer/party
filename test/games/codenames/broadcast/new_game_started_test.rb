# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module Codenames
  module Broadcast
    class NewGameStartedTest < ActiveSupport::TestCase
      include Turbo::Broadcastable::TestHelper

      test "#call broadcasts the fresh game to other online players" do
        game = create(:cn_completed_game)
        game.start_new_game(words: Words.instance.sample)
        actor = game.spymaster_for(Team.red)
        other = game.players.find { |player| player.name.to_s == "BlueOp" }
        PlayerConnections.instance.increment(other.id)

        streams = capture_turbo_stream_broadcasts other do
          NewGameStarted.new(game:, player: actor).call
        end

        assert_equal 1, streams.size
        assert_equal "game_frame", streams[0]["target"]
      end

      test "#call does not broadcast to the acting player" do
        game = create(:cn_completed_game)
        game.start_new_game(words: Words.instance.sample)
        actor = game.spymaster_for(Team.red)
        PlayerConnections.instance.increment(actor.id)

        assert_turbo_stream_broadcasts actor, count: 0 do
          NewGameStarted.new(game:, player: actor).call
        end
      end
    end
  end
end
