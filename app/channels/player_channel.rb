# frozen_string_literal: true

class PlayerChannel < ApplicationCable::Channel
  extend Turbo::Streams::Broadcasts
  extend Turbo::Streams::StreamName
  include Turbo::Streams::StreamName::ClassMethods

  def subscribed
    if (stream_name = verified_stream_name_from_params).present?
      @player = Player.find(stream_name)

      PlayerConnections.instance.increment(player.id)
      game.broadcast_reload_players

      stream_from stream_name
    else
      reject
    end
  end

  def unsubscribed
    return unless player

    PlayerConnections.instance.decrement(player.id)
    game.broadcast_reload_players
  end

  private

  attr_reader :player

  def game = player.game
end
