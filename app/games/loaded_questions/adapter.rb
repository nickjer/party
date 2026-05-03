# frozen_string_literal: true

module LoadedQuestions
  # Implements the _GameAdapter interface for PlayerChannel dispatch.
  class Adapter
    def on_player_connected(player_id)
      Broadcast::PlayerConnected.new(player_id:).call
    end

    def on_player_disconnected(player_id)
      Broadcast::PlayerDisconnected.new(player_id:).call
    end
  end
end
