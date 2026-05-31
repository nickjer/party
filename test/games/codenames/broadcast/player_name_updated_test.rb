# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module Codenames
  module Broadcast
    class PlayerNameUpdatedTest < ActiveSupport::TestCase
      include Turbo::Broadcastable::TestHelper

      test "#call re-renders the whole players list so it stays sorted" do
        game = create(:cn_playing_game)
        game.players.each do |player|
          PlayerConnections.instance.increment(player.id)
        end
        renamed = game.players.find { |player| player.name.to_s == "RedOp" }
        other = game.players.find { |player| player.name.to_s == "BlueOp" }

        streams = capture_turbo_stream_broadcasts other do
          PlayerNameUpdated.new(game:, player: renamed).call
        end

        # Updating the container (not replacing a single row) is what keeps
        # the renamed player sorted into the right position.
        assert_equal "update", streams[0]["action"]
        assert_equal "players", streams[0]["target"]
      end

      test "#call updates team_panels during setup" do
        game = create(:cn_game, :with_teams)
        game.players.each do |player|
          PlayerConnections.instance.increment(player.id)
        end
        renamed = game.spymaster_for(Team.red)
        other = game.spymaster_for(Team.blue)

        streams = capture_turbo_stream_broadcasts other do
          PlayerNameUpdated.new(game:, player: renamed).call
        end

        assert_equal "team_panels", streams[0]["target"]
      end

      test "#call does not broadcast to the renamed player" do
        game = create(:cn_playing_game)
        renamed = game.players.find { |player| player.name.to_s == "RedOp" }
        PlayerConnections.instance.increment(renamed.id)

        assert_turbo_stream_broadcasts renamed, count: 0 do
          PlayerNameUpdated.new(game:, player: renamed).call
        end
      end
    end
  end
end
