# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

class PlayerBroadcasterTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  test "#broadcast sends content to online players" do
    game = create(:lq_polling_game, player_names: %w[Alice])
    player = game.players.first
    PlayerConnections.instance.increment(player.id)

    assert_turbo_stream_broadcasts player.to_model, count: 1 do
      PlayerBroadcaster.new(players: game.players).broadcast do |_player|
        "<turbo-stream></turbo-stream>"
      end
    end
  end

  test "#broadcast skips offline players" do
    game = create(:lq_polling_game, player_names: %w[Alice])
    player = game.players.first
    # player is offline by default

    assert_turbo_stream_broadcasts player.to_model, count: 0 do
      PlayerBroadcaster.new(players: game.players).broadcast do |_player|
        "<turbo-stream></turbo-stream>"
      end
    end
  end

  test "#broadcast skips players when block returns nil" do
    game = create(:lq_polling_game, player_names: %w[Alice])
    player = game.players.first
    PlayerConnections.instance.increment(player.id)

    assert_turbo_stream_broadcasts player.to_model, count: 0 do
      PlayerBroadcaster.new(players: game.players).broadcast do |_player|
        nil
      end
    end
  end

  test "#broadcast yields each online player to the block" do
    game = create(:lq_polling_game, player_names: %w[Alice Bob])
    game.players.each do |player|
      PlayerConnections.instance.increment(player.id)
    end

    yielded_players = []
    PlayerBroadcaster.new(players: game.players).broadcast do |player|
      yielded_players << player
      nil
    end

    assert_equal game.players.map(&:id).sort, yielded_players.map(&:id).sort
  end
end
