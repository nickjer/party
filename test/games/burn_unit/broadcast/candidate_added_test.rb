# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module BurnUnit
  module Broadcast
    class CandidateAddedTest < ActiveSupport::TestCase
      include Turbo::Broadcastable::TestHelper

      test "#call broadcasts to other online players" do
        game = create(:bu_polling_game, player_names: %w[Alice Bob])
        alice = game.players.find { |p| p.name.to_s == "Alice" }
        bob = game.players.find { |p| p.name.to_s == "Bob" }

        # Mark players as online
        ::PlayerConnections.instance.increment(alice.id)
        ::PlayerConnections.instance.increment(bob.id)

        # Alice becoming candidate should broadcast to Bob
        assert_turbo_stream_broadcasts bob.to_model, count: 1 do
          CandidateAdded.new(game:, player: alice).call
        end
      end

      test "#call does not broadcast to candidate player" do
        game = create(:bu_polling_game, player_names: %w[Alice Bob])
        alice = game.players.find { |p| p.name.to_s == "Alice" }

        ::PlayerConnections.instance.increment(alice.id)

        # Alice becoming candidate should not broadcast to herself
        assert_turbo_stream_broadcasts alice.to_model, count: 0 do
          CandidateAdded.new(game:, player: alice).call
        end
      end

      test "#call does not broadcast to offline players" do
        game = create(:bu_polling_game, player_names: %w[Alice Bob])
        alice = game.players.find { |p| p.name.to_s == "Alice" }
        bob = game.players.find { |p| p.name.to_s == "Bob" }

        # Only Alice is online, Bob is offline
        ::PlayerConnections.instance.increment(alice.id)

        # Alice becoming candidate should not broadcast to offline Bob
        assert_turbo_stream_broadcasts bob.to_model, count: 0 do
          CandidateAdded.new(game:, player: alice).call
        end
      end

      test "#call broadcasts to multiple online players except candidate" do
        game = create(:bu_polling_game, player_names: %w[Alice Bob Charlie])
        alice = game.players.find { |p| p.name.to_s == "Alice" }
        bob = game.players.find { |p| p.name.to_s == "Bob" }
        charlie = game.players.find { |p| p.name.to_s == "Charlie" }

        # All players online
        ::PlayerConnections.instance.increment(alice.id)
        ::PlayerConnections.instance.increment(bob.id)
        ::PlayerConnections.instance.increment(charlie.id)

        # Alice becoming candidate should broadcast to Bob and Charlie
        assert_turbo_stream_broadcasts bob.to_model, count: 1 do
          assert_turbo_stream_broadcasts charlie.to_model, count: 1 do
            CandidateAdded.new(game:, player: alice).call
          end
        end
      end

      test "#call broadcasts append turbo stream action" do
        game = create(:bu_polling_game, player_names: %w[Alice Bob])
        alice = game.players.find { |p| p.name.to_s == "Alice" }
        bob = game.players.find { |p| p.name.to_s == "Bob" }

        ::PlayerConnections.instance.increment(bob.id)

        turbo_streams = capture_turbo_stream_broadcasts bob.to_model do
          CandidateAdded.new(game:, player: alice).call
        end

        assert_equal 1, turbo_streams.size
        assert_equal "append", turbo_streams[0]["action"]
        assert_equal "player_candidate_id", turbo_streams[0]["target"]
      end
    end
  end
end
