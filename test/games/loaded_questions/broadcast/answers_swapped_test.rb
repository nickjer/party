# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module LoadedQuestions
  module Broadcast
    class AnswersSwappedTest < ActiveSupport::TestCase
      include Turbo::Broadcastable::TestHelper

      test "#call broadcasts to online non-guesser players" do
        game = create(:lq_matching_game, player_names: %w[Alice Bob])
        game.players.find(&:guesser?)
        non_guesser = game.players.reject(&:guesser?).first

        # Mark non-guesser as online
        ::PlayerConnections.instance.increment(non_guesser.id)

        # Should broadcast to non-guesser
        assert_turbo_stream_broadcasts non_guesser.to_model, count: 1 do
          AnswersSwapped.new(game:).call
        end
      end

      test "#call does not broadcast to guesser" do
        game = create(:lq_matching_game, player_names: %w[Alice Bob])
        guesser = game.players.find(&:guesser?)

        # Mark guesser as online
        ::PlayerConnections.instance.increment(guesser.id)

        # Should not broadcast to guesser
        assert_turbo_stream_broadcasts guesser.to_model, count: 0 do
          AnswersSwapped.new(game:).call
        end
      end

      test "#call does not broadcast to offline non-guesser players" do
        game = create(:lq_matching_game, player_names: %w[Alice Bob])
        non_guesser = game.players.reject(&:guesser?).first

        # Non-guesser is offline

        # Should not broadcast to offline player
        assert_turbo_stream_broadcasts non_guesser.to_model, count: 0 do
          AnswersSwapped.new(game:).call
        end
      end

      test "#call broadcasts to multiple online non-guesser players" do
        game = create(:lq_matching_game, player_names: %w[Alice Bob Charlie])
        game.players.find(&:guesser?)
        non_guessers = game.players.reject(&:guesser?)

        # Mark non-guessers as online
        non_guessers.each { |p| ::PlayerConnections.instance.increment(p.id) }

        # Should broadcast to all non-guessers
        assert_turbo_stream_broadcasts non_guessers.first.to_model, count: 1 do
          assert_turbo_stream_broadcasts non_guessers.second.to_model,
            count: 1 do
            AnswersSwapped.new(game:).call
          end
        end
      end

      test "#call broadcasts update turbo stream action" do
        game = create(:lq_matching_game, player_names: %w[Alice Bob])
        non_guesser = game.players.reject(&:guesser?).first

        ::PlayerConnections.instance.increment(non_guesser.id)

        turbo_streams = capture_turbo_stream_broadcasts non_guesser.to_model do
          AnswersSwapped.new(game:).call
        end

        assert_equal 1, turbo_streams.size
        assert_equal "update", turbo_streams[0]["action"]
        assert_equal "answers", turbo_streams[0]["target"]
      end
    end
  end
end
