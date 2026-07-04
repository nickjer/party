# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module Codenames
  class AdapterTest < ActiveSupport::TestCase
    include Turbo::Broadcastable::TestHelper

    test "#on_player_connected broadcasts the player's row to other online " \
      "players" do
      game = create(:cn_playing_game)
      actor = game.spymaster_for(Team.red)
      other = player_named(game, "BlueOp")
      ::PlayerConnections.instance.increment(actor.id)
      ::PlayerConnections.instance.increment(other.id)

      assert_turbo_stream_broadcasts other, count: 1 do
        Adapter.on_player_connected(actor.id)
      end
    end

    test "#on_player_disconnected broadcasts the player's row to other " \
      "online players" do
      game = create(:cn_playing_game)
      actor = game.spymaster_for(Team.red)
      other = player_named(game, "BlueOp")
      ::PlayerConnections.instance.increment(actor.id)
      ::PlayerConnections.instance.increment(other.id)

      assert_turbo_stream_broadcasts other, count: 1 do
        Adapter.on_player_disconnected(actor.id)
      end
    end

    private

    def player_named(game, name)
      game.players.find { |player| player.name.to_s == name }
    end
  end
end
