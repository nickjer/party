# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module Wavelength
  module Broadcast
    class DialMovedTest < ActiveSupport::TestCase
      include Turbo::Broadcastable::TestHelper

      test "#call broadcasts to other online players" do
        game = online_game
        actor = player_named(game:, name: "RedOne")
        other = player_named(game:, name: "BlueOne")

        assert_turbo_stream_broadcasts other, count: 1 do
          DialMoved.new(game:, player: actor).call
        end
      end

      test "#call does not broadcast to the acting player" do
        game = online_game
        actor = player_named(game:, name: "RedOne")

        assert_turbo_stream_broadcasts actor, count: 0 do
          DialMoved.new(game:, player: actor).call
        end
      end

      test "#call updates the dial marker target" do
        game = online_game
        actor = player_named(game:, name: "RedOne")
        other = player_named(game:, name: "BlueOne")

        streams = capture_turbo_stream_broadcasts other do
          DialMoved.new(game:, player: actor).call
        end

        assert_equal "update", streams[0]["action"]
        assert_equal "wl_dial_marker_#{game.id}", streams[0]["target"]
      end

      private

      def online_game
        game = create(:wl_guessing_game)
        game.players.each do |player|
          PlayerConnections.instance.increment(player.id)
        end
        game
      end
    end
  end
end
