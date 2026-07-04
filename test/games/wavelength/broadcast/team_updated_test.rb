# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module Wavelength
  module Broadcast
    class TeamUpdatedTest < ActiveSupport::TestCase
      include Turbo::Broadcastable::TestHelper

      test "#call broadcasts the team panels to other online players" do
        game = create(:wl_game, :with_teams)
        actor = player_named(game:, name: "RedOne")
        other = player_named(game:, name: "BlueOne")
        PlayerConnections.instance.increment(other.id)

        streams = capture_turbo_stream_broadcasts other do
          TeamUpdated.new(game:, player: actor).call
        end

        assert_equal 1, streams.size
        assert_equal "team_panels", streams[0]["target"]
      end

      test "#call does not broadcast to the acting player" do
        game = create(:wl_game, :with_teams)
        actor = player_named(game:, name: "RedOne")
        PlayerConnections.instance.increment(actor.id)

        assert_turbo_stream_broadcasts actor, count: 0 do
          TeamUpdated.new(game:, player: actor).call
        end
      end
    end
  end
end
