# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module BurnUnit
  module Broadcast
    class RoundCompletedTest < ActiveSupport::TestCase
      include Turbo::Broadcastable::TestHelper

      test "#call broadcasts to online non-judge players" do
        game = create(:bu_completed_game, player_names: %w[Alice Bob])
        game.players.find(&:judge?)
        non_judge = game.players.reject(&:judge?).first

        # Mark non-judge as online
        ::PlayerConnections.instance.increment(non_judge.id)

        # Should broadcast to non-judge (round_frame + players div)
        assert_turbo_stream_broadcasts non_judge.to_model, count: 2 do
          RoundCompleted.new(game:).call
        end
      end

      test "#call does not broadcast to judge" do
        game = create(:bu_completed_game, player_names: %w[Alice Bob])
        judge = game.players.find(&:judge?)

        # Mark judge as online
        ::PlayerConnections.instance.increment(judge.id)

        # Should not broadcast to judge
        assert_turbo_stream_broadcasts judge.to_model, count: 0 do
          RoundCompleted.new(game:).call
        end
      end

      test "#call does not broadcast to offline non-judge players" do
        game = create(:bu_completed_game, player_names: %w[Alice Bob])
        non_judge = game.players.reject(&:judge?).first

        # Non-judge is offline

        # Should not broadcast to offline player
        assert_turbo_stream_broadcasts non_judge.to_model, count: 0 do
          RoundCompleted.new(game:).call
        end
      end

      test "#call broadcasts to multiple online non-judge players" do
        game = create(:bu_completed_game, player_names: %w[Alice Bob Charlie])
        game.players.find(&:judge?)
        non_judges = game.players.reject(&:judge?)

        # Mark non-judges as online
        non_judges.each { |p| ::PlayerConnections.instance.increment(p.id) }

        # Should broadcast to all non-judges (round_frame + players div)
        assert_turbo_stream_broadcasts non_judges.first.to_model, count: 2 do
          assert_turbo_stream_broadcasts non_judges.second.to_model,
            count: 2 do
            RoundCompleted.new(game:).call
          end
        end
      end

      test "#call broadcasts update turbo stream action" do
        game = create(:bu_completed_game, player_names: %w[Alice Bob])
        non_judge = game.players.reject(&:judge?).first

        ::PlayerConnections.instance.increment(non_judge.id)

        turbo_streams = capture_turbo_stream_broadcasts non_judge.to_model do
          RoundCompleted.new(game:).call
        end

        assert_equal 2, turbo_streams.size
        assert_equal "update", turbo_streams[0]["action"]
        assert_equal "round_frame", turbo_streams[0]["target"]
        assert_equal "update", turbo_streams[1]["action"]
        assert_equal "players", turbo_streams[1]["target"]
      end
    end
  end
end
