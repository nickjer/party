# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module Codenames
  module Broadcast
    class PlayerCreatedTest < ActiveSupport::TestCase
      include Turbo::Broadcastable::TestHelper

      test "#call broadcasts to other online players but not the new one" do
        game = create(:cn_game)
        alice = game.add_player(user_id: create(:user).id,
          name: PlayerName.parse("Alice"))
        bob = game.add_player(user_id: create(:user).id,
          name: PlayerName.parse("Bob"))
        Codenames::GameRepo.save(game)
        PlayerConnections.instance.increment(alice.id)
        PlayerConnections.instance.increment(bob.id)

        assert_turbo_stream_broadcasts alice, count: 1 do
          assert_turbo_stream_broadcasts bob, count: 0 do
            PlayerCreated.new(game:, player: bob).call
          end
        end
      end

      test "#call updates the team_panels target during setup" do
        game = create(:cn_game)
        alice = game.add_player(user_id: create(:user).id,
          name: PlayerName.parse("Alice"))
        bob = game.add_player(user_id: create(:user).id,
          name: PlayerName.parse("Bob"))
        Codenames::GameRepo.save(game)
        PlayerConnections.instance.increment(alice.id)

        streams = capture_turbo_stream_broadcasts alice do
          PlayerCreated.new(game:, player: bob).call
        end

        assert_equal "team_panels", streams[0]["target"]
      end
    end
  end
end
