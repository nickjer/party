# frozen_string_literal: true

require "test_helper"

module Codenames
  class AdapterTest < ActiveSupport::TestCase
    test "#on_player_connected dispatches to PlayerConnected" do
      adapter = Adapter.new
      broadcast = mock
      broadcast.expects(:call)
      Broadcast::PlayerConnected.expects(:new).with(player_id: "p1")
        .returns(broadcast)

      adapter.on_player_connected("p1")
    end

    test "#on_player_disconnected dispatches to PlayerDisconnected" do
      adapter = Adapter.new
      broadcast = mock
      broadcast.expects(:call)
      Broadcast::PlayerDisconnected.expects(:new).with(player_id: "p1")
        .returns(broadcast)

      adapter.on_player_disconnected("p1")
    end
  end
end
