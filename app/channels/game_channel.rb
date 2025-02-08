# frozen_string_literal: true

class GameChannel < ApplicationCable::Channel
  extend Turbo::Streams::Broadcasts
  extend Turbo::Streams::StreamName
  include Turbo::Streams::StreamName::ClassMethods

  def subscribed
    if (stream_name = verified_stream_name_from_params).present?
      @game = GlobalID.find(stream_name)
      PlayerConnections.instance.increment(player.id)
      reload_players

      stream_from stream_name
    else
      reject
    end
  end

  def unsubscribed
    PlayerConnections.instance.decrement(player.id)
    reload_players
  end

  private

  attr_reader :game

  def player = @player ||= Player.find_by!(game_id: game.id, user_id:)

  def reload_players
    ::Turbo::StreamsChannel.broadcast_action_to(
      game, action: :reload, target: "players"
    )
  end

  def user_id = current_user.id
end
