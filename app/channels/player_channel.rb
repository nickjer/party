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
    stream_name = verified_stream_name_from_params
    return reject unless stream_name

    @player = GlobalID.find(stream_name) || raise("Invalid player GID")
    return reject if player.user != current_user

    stream_from stream_name

    count = ::PlayerConnections.instance.increment(player.id)
    return if count > 1

    broadcaster =
      case game_kind
      when :burn_unit
        BurnUnit::Broadcast::PlayerConnected.new(player_id: player.id)
      when :loaded_questions
        LoadedQuestions::Broadcast::PlayerConnected.new(player_id: player.id)
      else
        raise "Unknown game kind: #{game_kind.inspect}"
      end
    broadcaster.call
  end

  def unsubscribed
    count = ::PlayerConnections.instance.decrement(player.id)
    return if count.positive?

    broadcaster =
      case game_kind
      when :burn_unit
        BurnUnit::Broadcast::PlayerDisconnected.new(player_id: player.id)
      when :loaded_questions
        LoadedQuestions::Broadcast::PlayerDisconnected.new(player_id: player.id)
      else
        raise "Unknown game kind: #{game_kind.inspect}"
      end
    broadcaster.call
  end

  private

  # @dynamic player
  attr_reader :player

  def game_kind = @game_kind = player.game.kind
end
