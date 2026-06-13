# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module Wavelength
  module Broadcast
    class RoundUpdatedTest < ActiveSupport::TestCase
      include Turbo::Broadcastable::TestHelper

      test "#call broadcasts to other online players" do
        game = online_game
        actor = player_named(game, "RedOne")
        other = player_named(game, "BlueOne")

        assert_turbo_stream_broadcasts other, count: 1 do
          RoundUpdated.new(game:, player: actor).call
        end
      end

      test "#call does not broadcast to the acting player" do
        game = online_game
        actor = player_named(game, "RedOne")

        assert_turbo_stream_broadcasts actor, count: 0 do
          RoundUpdated.new(game:, player: actor).call
        end
      end

      test "#call updates the play_area target" do
        game = online_game
        actor = player_named(game, "RedOne")
        other = player_named(game, "BlueOne")

        streams = capture_turbo_stream_broadcasts other do
          RoundUpdated.new(game:, player: actor).call
        end

        assert_equal "update", streams[0]["action"]
        assert_equal "play_area", streams[0]["target"]
      end

      test "#call swaps the frame for a teamless joiner when the game ends" do
        game = create(:wl_completed_game)
        latecomer = game.add_player(
          user_id: create(:user).id, name: PlayerName.parse("Late")
        )
        Wavelength::GameRepo.save(game)
        PlayerConnections.instance.increment(latecomer.id)
        actor = player_named(game, "RedOne")

        streams = capture_turbo_stream_broadcasts latecomer do
          RoundUpdated.new(game:, player: actor).call
        end

        assert_equal "update", streams[0]["action"]
        assert_equal "game_frame", streams[0]["target"]
      end

      private

      def online_game
        game = create(:wl_guessing_game)
        game.players.each do |player|
          PlayerConnections.instance.increment(player.id)
        end
        game
      end

      def player_named(game, name)
        game.players.find { |player| player.name.to_s == name }
      end
    end
  end
end
