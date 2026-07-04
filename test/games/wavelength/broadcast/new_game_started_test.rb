# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module Wavelength
  module Broadcast
    class NewGameStartedTest < ActiveSupport::TestCase
      include Turbo::Broadcastable::TestHelper

      test "#call broadcasts the fresh lobby to other online players" do
        game = create(:wl_completed_game)
        game.start_new_game(spectrum: Spectrums.instance.sample,
          target: Game::Target.new(position: 50))
        actor = player_named(game:, name: "RedOne")
        other = player_named(game:, name: "BlueOne")
        PlayerConnections.instance.increment(other.id)

        streams = capture_turbo_stream_broadcasts other do
          NewGameStarted.new(game:, player: actor).call
        end

        assert_equal 1, streams.size
        assert_equal "game_frame", streams[0]["target"]
      end

      test "#call does not broadcast to the acting player" do
        game = create(:wl_completed_game)
        game.start_new_game(spectrum: Spectrums.instance.sample,
          target: Game::Target.new(position: 50))
        actor = player_named(game:, name: "RedOne")
        PlayerConnections.instance.increment(actor.id)

        assert_turbo_stream_broadcasts actor, count: 0 do
          NewGameStarted.new(game:, player: actor).call
        end
      end
    end
  end
end
