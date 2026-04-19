# frozen_string_literal: true

# Collaborator for sending Turbo Stream broadcasts to a set of players.
# Instantiate with the players to broadcast to, then call `broadcast` with
# a block that returns the stream content (or nil to skip) for each online
# player.
class PlayerBroadcaster
  def initialize(players:)
    @players = players
  end

  def broadcast(&block)
    players.each do |player|
      next unless player.online?

      content = block.call(player)
      next unless content

      Turbo::StreamsChannel.broadcast_stream_to(player.to_model, content:)
    end
  end

  private

  # @dynamic players
  attr_reader :players
end
