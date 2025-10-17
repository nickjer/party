# frozen_string_literal: true

# Thread-safe singleton that tracks online player connections using Concurrent::Map.
class PlayerConnections
  include Singleton

  # @dynamic self.instance

  def initialize = @connection_map = Concurrent::Map.new

  def count(player_id) = connection_map.fetch(player_id, 0)

  def increment(player_id)
    connection_map.compute(player_id) { |old_count| (old_count || 0) + 1 }
  end

  def decrement(player_id)
    connection_map.compute(player_id) do |old_count|
      new_count = (old_count || 0) - 1
      new_count.positive? ? new_count : 0
    end
  end

  private

  # @dynamic connection_map
  attr_reader :connection_map
end
