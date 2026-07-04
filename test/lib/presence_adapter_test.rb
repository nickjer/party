# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

class PresenceAdapterTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  test "#on_player_connected broadcasts the player's row to other online " \
    "players" do
    game = create(:lq_polling_game, player_names: %w[Alice Bob])
    alice = player_named(game, "Alice")
    bob = player_named(game, "Bob")
    ::PlayerConnections.instance.increment(alice.id)
    ::PlayerConnections.instance.increment(bob.id)

    assert_turbo_stream_broadcasts bob, count: 1 do
      adapter.on_player_connected(alice.id)
    end
  end

  test "#on_player_connected does not broadcast to the acting player" do
    game = create(:lq_polling_game, player_names: %w[Alice Bob])
    alice = player_named(game, "Alice")
    ::PlayerConnections.instance.increment(alice.id)

    assert_turbo_stream_broadcasts alice, count: 0 do
      adapter.on_player_connected(alice.id)
    end
  end

  test "#on_player_connected does not broadcast to offline players" do
    game = create(:lq_polling_game, player_names: %w[Alice Bob])
    alice = player_named(game, "Alice")
    bob = player_named(game, "Bob")
    ::PlayerConnections.instance.increment(alice.id)

    assert_turbo_stream_broadcasts bob, count: 0 do
      adapter.on_player_connected(alice.id)
    end
  end

  test "#on_player_connected broadcasts to multiple online players except " \
    "the acting player" do
    game = create(:lq_polling_game, player_names: %w[Alice Bob Charlie])
    alice = player_named(game, "Alice")
    bob = player_named(game, "Bob")
    charlie = player_named(game, "Charlie")
    game.players.each do |player|
      ::PlayerConnections.instance.increment(player.id)
    end

    assert_turbo_stream_broadcasts bob, count: 1 do
      assert_turbo_stream_broadcasts charlie, count: 1 do
        adapter.on_player_connected(alice.id)
      end
    end
  end

  test "#on_player_connected handles a game with only the acting player" do
    game = create(:lq_game, :with_guesser)
    alice = game.players.first
    ::PlayerConnections.instance.increment(alice.id)

    assert_nothing_raised do
      adapter.on_player_connected(alice.id)
    end
  end

  test "#on_player_connected broadcasts a replace stream targeting the " \
    "player's row" do
    game = create(:lq_polling_game, player_names: %w[Alice Bob])
    alice = player_named(game, "Alice")
    bob = player_named(game, "Bob")
    ::PlayerConnections.instance.increment(alice.id)
    ::PlayerConnections.instance.increment(bob.id)

    turbo_streams = capture_turbo_stream_broadcasts bob do
      adapter.on_player_connected(alice.id)
    end

    assert_equal 1, turbo_streams.size
    assert_equal "replace", turbo_streams[0]["action"]
    assert_equal "player_#{alice.id}", turbo_streams[0]["target"]
  end

  test "#on_player_disconnected broadcasts the player's row to other " \
    "online players" do
    game = create(:lq_polling_game, player_names: %w[Alice Bob])
    alice = player_named(game, "Alice")
    bob = player_named(game, "Bob")
    ::PlayerConnections.instance.increment(alice.id)
    ::PlayerConnections.instance.increment(bob.id)

    assert_turbo_stream_broadcasts bob, count: 1 do
      adapter.on_player_disconnected(alice.id)
    end
  end

  test "#on_player_disconnected does not broadcast to the acting player" do
    game = create(:lq_polling_game, player_names: %w[Alice Bob])
    alice = player_named(game, "Alice")
    bob = player_named(game, "Bob")
    ::PlayerConnections.instance.increment(alice.id)
    ::PlayerConnections.instance.increment(bob.id)

    assert_turbo_stream_broadcasts alice, count: 0 do
      adapter.on_player_disconnected(alice.id)
    end
  end

  private

  def adapter
    PresenceAdapter.new(repo: LoadedQuestions::GameRepo,
      template: "loaded_questions/players/presence")
  end

  def player_named(game, name)
    game.players.find { |player| player.name.to_s == name }
  end
end
