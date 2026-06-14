# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module Wavelength
  module Broadcast
    class PlayerDisconnectedTest < ActiveSupport::TestCase
      include Turbo::Broadcastable::TestHelper

      test "#call broadcasts to other online players" do
        game = create(:wl_guessing_game)
        actor = player_named(game, "RedOne")
        other = player_named(game, "BlueOne")
        game.players.each do |player|
          PlayerConnections.instance.increment(player.id)
        end

        assert_turbo_stream_broadcasts other, count: 1 do
          PlayerDisconnected.new(player_id: actor.id).call
        end
      end

      test "#call does not broadcast to the disconnected player" do
        game = create(:wl_guessing_game)
        actor = player_named(game, "RedOne")
        PlayerConnections.instance.increment(actor.id)

        assert_turbo_stream_broadcasts actor, count: 0 do
          PlayerDisconnected.new(player_id: actor.id).call
        end
      end

      test "#call does not broadcast to offline players" do
        game = create(:wl_guessing_game)
        actor = player_named(game, "RedOne")
        other = player_named(game, "BlueOne")
        PlayerConnections.instance.increment(actor.id)

        assert_turbo_stream_broadcasts other, count: 0 do
          PlayerDisconnected.new(player_id: actor.id).call
        end
      end

      private

      def player_named(game, name)
        game.players.find { |player| player.name.to_s == name }
      end
    end
  end
end
