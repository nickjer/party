# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module LoadedQuestions
  module Broadcast
    class RoundCreatedTest < ActiveSupport::TestCase
      include Turbo::Broadcastable::TestHelper

      test "#call broadcasts to online non-guesser players" do
        game = create(:lq_polling_game, player_names: %w[Alice Bob])
        game.players.find(&:guesser?)
        non_guesser = game.players.reject(&:guesser?).first

        # Mark non-guesser as online
        ::PlayerConnections.instance.increment(non_guesser.id)

        # Should broadcast to non-guesser
        turbo_streams = capture_turbo_stream_broadcasts non_guesser.to_model do
          RoundCreated.new(game_id: game.id).call
        end

        assert_equal 2, turbo_streams.size
        assert_equal "update", turbo_streams[0]["action"]
        assert_equal "round_frame", turbo_streams[0]["target"]
        assert_equal "update", turbo_streams[1]["action"]
        assert_equal "players", turbo_streams[1]["target"]
      end

      test "#call does not broadcast to guesser" do
        game = create(:lq_polling_game, player_names: %w[Alice Bob])
        guesser = game.players.find(&:guesser?)

        # Mark guesser as online
        ::PlayerConnections.instance.increment(guesser.id)

        # Should not broadcast to guesser
        assert_turbo_stream_broadcasts guesser.to_model, count: 0 do
          RoundCreated.new(game_id: game.id).call
        end
      end

      test "#call does not broadcast to offline non-guesser players" do
        game = create(:lq_polling_game, player_names: %w[Alice Bob])
        non_guesser = game.players.reject(&:guesser?).first

        # Non-guesser is offline

        # Should not broadcast to offline player
        assert_turbo_stream_broadcasts non_guesser.to_model, count: 0 do
          RoundCreated.new(game_id: game.id).call
        end
      end

      test "#call broadcasts to multiple online non-guesser players" do
        game = create(:lq_polling_game, player_names: %w[Alice Bob Charlie])
        game.players.find(&:guesser?)
        non_guessers = game.players.reject(&:guesser?)

        # Mark non-guessers as online
        non_guessers.each { |p| ::PlayerConnections.instance.increment(p.id) }

        # Should broadcast to all non-guessers
        # (2 turbo-stream actions per player)
        assert_turbo_stream_broadcasts non_guessers.first.to_model, count: 2 do
          assert_turbo_stream_broadcasts non_guessers.second.to_model,
            count: 2 do
            RoundCreated.new(game_id: game.id).call
          end
        end
      end
    end
  end
end
