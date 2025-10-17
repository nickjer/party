# frozen_string_literal: true

# Player-level ActionCable channel for real-time game updates
# and connection tracking.
class PlayerChannel < ApplicationCable::Channel
  extend Turbo::Streams::Broadcasts
  extend Turbo::Streams::StreamName
  include Turbo::Streams::StreamName::ClassMethods

  class << self
    def broadcast_to(players, &block)
      players.each do |player|
        next unless player.online?

        content = block.call(player)
        next unless content

        ::Turbo::StreamsChannel.broadcast_stream_to(player.to_model, content:)
      end
    end
  end

  def subscribed
    if (stream_name = verified_stream_name_from_params)
      @player = GlobalID.find(stream_name) || raise("Invalid player GID")

      ::PlayerConnections.instance.increment(player.id)
      game.broadcast_reload_players

      stream_from stream_name
    else
      reject
    end
  end

  def unsubscribed
    ::PlayerConnections.instance.decrement(player.id)
    game.broadcast_reload_players
  end

  private

  # @dynamic player
  attr_reader :player

  def game = player.game
end
