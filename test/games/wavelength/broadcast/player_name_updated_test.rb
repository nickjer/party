# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module Wavelength
  module Broadcast
    class PlayerNameUpdatedTest < ActiveSupport::TestCase
      include Turbo::Broadcastable::TestHelper

      test "#call re-renders the whole players list so it stays sorted" do
        game = create(:wl_guessing_game)
        game.players.each do |player|
          PlayerConnections.instance.increment(player.id)
        end
        renamed = player_named(game, "RedOne")
        other = player_named(game, "BlueOne")

        streams = capture_turbo_stream_broadcasts other do
          PlayerNameUpdated.new(game:, player: renamed).call
        end

        assert_equal "update", streams[0]["action"]
        assert_equal "players", streams[0]["target"]
      end

      test "#call updates team_panels during setup" do
        game = create(:wl_game, :with_teams)
        game.players.each do |player|
          PlayerConnections.instance.increment(player.id)
        end
        renamed = player_named(game, "RedOne")
        other = player_named(game, "BlueOne")

        streams = capture_turbo_stream_broadcasts other do
          PlayerNameUpdated.new(game:, player: renamed).call
        end

        assert_equal "team_panels", streams[0]["target"]
      end

      test "#call does not broadcast to the renamed player" do
        game = create(:wl_guessing_game)
        renamed = player_named(game, "RedOne")
        PlayerConnections.instance.increment(renamed.id)

        assert_turbo_stream_broadcasts renamed, count: 0 do
          PlayerNameUpdated.new(game:, player: renamed).call
        end
      end

      private

      def player_named(game, name)
        game.players.find { |player| player.name.to_s == name }
      end
    end
  end
end
