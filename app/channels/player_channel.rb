# frozen_string_literal: true

# Player-level ActionCable channel for real-time game updates
# and connection tracking.
class PlayerChannel < ApplicationCable::Channel
  extend Turbo::Streams::StreamName
  include Turbo::Streams::StreamName::ClassMethods

  def subscribed
    stream_name = verified_stream_name_from_params
    return reject unless stream_name

    @player = GlobalID.find(stream_name) || raise("Invalid player GID")
    return reject if player.user != current_user

    stream_from stream_name

    count = ::PlayerConnections.instance.increment(player.id)
    return if count > 1

    adapter.on_player_connected(player.id)
  end

  def unsubscribed
    count = ::PlayerConnections.instance.decrement(player.id)
    return if count.positive?

    adapter.on_player_disconnected(player.id)
  end

  private

  # @dynamic player
  attr_reader :player

  def adapter
    @adapter ||= begin
      kind = player.game.kind
      case kind
      when :loaded_questions then LoadedQuestions::Adapter.new
      when :burn_unit then BurnUnit::Adapter.new
      else raise "Unknown game kind: #{kind.inspect}"
      end
    end
  end
end
