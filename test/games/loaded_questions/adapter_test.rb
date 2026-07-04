# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module LoadedQuestions
  class AdapterTest < ActiveSupport::TestCase
    include Turbo::Broadcastable::TestHelper

    test "#on_player_connected broadcasts the player's row to other online " \
      "players" do
      game = create(:lq_polling_game, player_names: %w[Alice Bob])
      alice = player_named(game, "Alice")
      bob = player_named(game, "Bob")
      ::PlayerConnections.instance.increment(alice.id)
      ::PlayerConnections.instance.increment(bob.id)

      assert_turbo_stream_broadcasts bob, count: 1 do
        Adapter.on_player_connected(alice.id)
      end
    end

    test "#on_player_disconnected broadcasts the player's row to other " \
      "online players" do
      game = create(:lq_polling_game, player_names: %w[Alice Bob])
      alice = player_named(game, "Alice")
      bob = player_named(game, "Bob")
      ::PlayerConnections.instance.increment(alice.id)
      ::PlayerConnections.instance.increment(bob.id)

      assert_turbo_stream_broadcasts bob, count: 1 do
        Adapter.on_player_disconnected(alice.id)
      end
    end

    private

    def player_named(game, name)
      game.players.find { |player| player.name.to_s == name }
    end
  end
end
