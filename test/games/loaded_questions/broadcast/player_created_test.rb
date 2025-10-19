# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module LoadedQuestions
  module Broadcast
    class PlayerCreatedTest < ActiveSupport::TestCase
      include Turbo::Broadcastable::TestHelper

      test "#call broadcasts to other online players" do
        game = create(:lq_game, player_names: %w[Alice Bob])
        alice = game.players.find { |p| p.name.to_s == "Alice" }
        bob = game.players.find { |p| p.name.to_s == "Bob" }

        # Mark players as online
        ::PlayerConnections.instance.increment(alice.id)
        ::PlayerConnections.instance.increment(bob.id)

        # Bob being created should broadcast to Alice
        assert_turbo_stream_broadcasts alice.to_model, count: 1 do
          PlayerCreated.new(player_id: bob.id).call
        end
      end

      test "#call does not broadcast to created player" do
        game = create(:lq_game, player_names: %w[Alice Bob])
        alice = game.players.find { |p| p.name.to_s == "Alice" }
        bob = game.players.find { |p| p.name.to_s == "Bob" }

        # Mark players as online
        ::PlayerConnections.instance.increment(alice.id)
        ::PlayerConnections.instance.increment(bob.id)

        # Bob being created should not broadcast to Bob himself
        assert_turbo_stream_broadcasts bob.to_model, count: 0 do
          PlayerCreated.new(player_id: bob.id).call
        end
      end

      test "#call does not broadcast to offline players" do
        game = create(:lq_game, player_names: %w[Alice Bob])
        alice = game.players.find { |p| p.name.to_s == "Alice" }
        bob = game.players.find { |p| p.name.to_s == "Bob" }

        # Only Bob is online, Alice is offline
        ::PlayerConnections.instance.increment(bob.id)

        # Bob being created should not broadcast to offline Alice
        assert_turbo_stream_broadcasts alice.to_model, count: 0 do
          PlayerCreated.new(player_id: bob.id).call
        end
      end

      test "#call broadcasts to multiple online players except created " \
        "player" do
        game = create(:lq_game, player_names: %w[Alice Bob Charlie])
        alice = game.players.find { |p| p.name.to_s == "Alice" }
        bob = game.players.find { |p| p.name.to_s == "Bob" }
        charlie = game.players.find { |p| p.name.to_s == "Charlie" }

        # All players online
        ::PlayerConnections.instance.increment(alice.id)
        ::PlayerConnections.instance.increment(bob.id)
        ::PlayerConnections.instance.increment(charlie.id)

        # Charlie being created should broadcast to Alice and Bob
        # but not to Charlie
        assert_turbo_stream_broadcasts alice.to_model, count: 1 do
          assert_turbo_stream_broadcasts bob.to_model, count: 1 do
            PlayerCreated.new(player_id: charlie.id).call
          end
        end
      end

      test "#call broadcasts update turbo stream action" do
        game = create(:lq_game, player_names: %w[Alice Bob])
        alice = game.players.find { |p| p.name.to_s == "Alice" }
        bob = game.players.find { |p| p.name.to_s == "Bob" }

        ::PlayerConnections.instance.increment(alice.id)

        turbo_streams = capture_turbo_stream_broadcasts alice.to_model do
          PlayerCreated.new(player_id: bob.id).call
        end

        assert_equal 1, turbo_streams.size
        assert_equal "update", turbo_streams[0]["action"]
        assert_equal "players", turbo_streams[0]["target"]
      end
    end
  end
end
