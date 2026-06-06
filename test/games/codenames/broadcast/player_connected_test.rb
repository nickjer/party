# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module Codenames
  module Broadcast
    class PlayerConnectedTest < ActiveSupport::TestCase
      include Turbo::Broadcastable::TestHelper

      test "#call broadcasts to other online players" do
        game = create(:cn_playing_game)
        actor = game.spymaster_for(Team.red)
        other = game.players.find { |player| player.name.to_s == "BlueOp" }
        game.players.each do |player|
          PlayerConnections.instance.increment(player.id)
        end

        assert_turbo_stream_broadcasts other, count: 1 do
          PlayerConnected.new(player_id: actor.id).call
        end
      end

      test "#call does not broadcast to the connected player" do
        game = create(:cn_playing_game)
        actor = game.spymaster_for(Team.red)
        PlayerConnections.instance.increment(actor.id)

        assert_turbo_stream_broadcasts actor, count: 0 do
          PlayerConnected.new(player_id: actor.id).call
        end
      end

      test "#call does not broadcast to offline players" do
        game = create(:cn_playing_game)
        actor = game.spymaster_for(Team.red)
        other = game.players.find { |player| player.name.to_s == "BlueOp" }
        PlayerConnections.instance.increment(actor.id)

        assert_turbo_stream_broadcasts other, count: 0 do
          PlayerConnected.new(player_id: actor.id).call
        end
      end
    end
  end
end
