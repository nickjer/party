# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class AdapterTest < ActiveSupport::TestCase
    test "#on_player_connected delegates to Broadcast::PlayerConnected" do
      player_id = "player-123"
      broadcaster = mock
      broadcaster.expects(:call).once
      Broadcast::PlayerConnected
        .expects(:new).with(player_id:).returns(broadcaster)

      Adapter.new.on_player_connected(player_id)
    end

    test "#on_player_disconnected delegates to Broadcast::PlayerDisconnected" do
      player_id = "player-456"
      broadcaster = mock
      broadcaster.expects(:call).once
      Broadcast::PlayerDisconnected
        .expects(:new).with(player_id:).returns(broadcaster)

      Adapter.new.on_player_disconnected(player_id)
    end
  end
end
