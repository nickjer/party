# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module BurnUnit
  class AdapterTest < ActiveSupport::TestCase
    include Turbo::Broadcastable::TestHelper

    test "#on_player_connected broadcasts the player's row to other online " \
      "players" do
      game = create(:bu_polling_game, player_names: %w[Alice Bob])
      alice = player_named(game:, name: "Alice")
      bob = player_named(game:, name: "Bob")
      ::PlayerConnections.instance.increment(alice.id)
      ::PlayerConnections.instance.increment(bob.id)

      assert_turbo_stream_broadcasts bob, count: 1 do
        Adapter.on_player_connected(alice.id)
      end
    end
  end
end
