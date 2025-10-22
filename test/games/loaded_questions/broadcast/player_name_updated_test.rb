# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module LoadedQuestions
  module Broadcast
    class PlayerNameUpdatedTest < ActiveSupport::TestCase
      include Turbo::Broadcastable::TestHelper

      test "#call broadcasts to all online players" do
        game = create(:lq_polling_game, player_names: %w[Alice Bob])
        alice = game.players.find { |p| p.name.to_s == "Alice" }
        bob = game.players.find { |p| p.name.to_s == "Bob" }

        # Mark players as online
        ::PlayerConnections.instance.increment(alice.id)
        ::PlayerConnections.instance.increment(bob.id)

        # Alice name update should broadcast to both Alice and Bob
        assert_turbo_stream_broadcasts alice.to_model, count: 1 do
          assert_turbo_stream_broadcasts bob.to_model, count: 1 do
            PlayerNameUpdated.new(player_id: alice.id).call
          end
        end
      end

      test "#call broadcasts to updated player" do
        game = create(:lq_polling_game, player_names: %w[Alice Bob])
        alice = game.players.find { |p| p.name.to_s == "Alice" }

        # Mark Alice as online
        ::PlayerConnections.instance.increment(alice.id)

        # Alice name update should broadcast to Alice herself
        assert_turbo_stream_broadcasts alice.to_model, count: 1 do
          PlayerNameUpdated.new(player_id: alice.id).call
        end
      end

      test "#call does not broadcast to offline players" do
        game = create(:lq_polling_game, player_names: %w[Alice Bob])
        alice = game.players.find { |p| p.name.to_s == "Alice" }
        bob = game.players.find { |p| p.name.to_s == "Bob" }

        # Only Alice is online, Bob is offline
        ::PlayerConnections.instance.increment(alice.id)

        # Alice name update should not broadcast to offline Bob
        assert_turbo_stream_broadcasts bob.to_model, count: 0 do
          PlayerNameUpdated.new(player_id: alice.id).call
        end
      end

      test "#call broadcasts to multiple online players" do
        game = create(:lq_polling_game, player_names: %w[Alice Bob Charlie])
        alice = game.players.find { |p| p.name.to_s == "Alice" }
        bob = game.players.find { |p| p.name.to_s == "Bob" }
        charlie = game.players.find { |p| p.name.to_s == "Charlie" }

        # All players online
        ::PlayerConnections.instance.increment(alice.id)
        ::PlayerConnections.instance.increment(bob.id)
        ::PlayerConnections.instance.increment(charlie.id)

        # Alice name update should broadcast to all online players
        assert_turbo_stream_broadcasts alice.to_model, count: 1 do
          assert_turbo_stream_broadcasts bob.to_model, count: 1 do
            assert_turbo_stream_broadcasts charlie.to_model, count: 1 do
              PlayerNameUpdated.new(player_id: alice.id).call
            end
          end
        end
      end

      test "#call broadcasts update turbo stream action" do
        game = create(:lq_polling_game, player_names: %w[Alice Bob])
        alice = game.players.find { |p| p.name.to_s == "Alice" }

        ::PlayerConnections.instance.increment(alice.id)

        turbo_streams = capture_turbo_stream_broadcasts alice.to_model do
          PlayerNameUpdated.new(player_id: alice.id).call
        end

        assert_equal 1, turbo_streams.size
        assert_equal "update", turbo_streams[0]["action"]
        assert_equal "players", turbo_streams[0]["target"]
      end
    end
  end
end
