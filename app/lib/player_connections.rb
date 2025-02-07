# frozen_string_literal: true

class PlayerConnections
  include Singleton

  # @dynamic self.instance

  def initialize = @connection_map = ScoreMap.new

  def count(player_id) = connection_map.score(player_id)

  def increment(player_id) = connection_map.increment_by(player_id, 1)

  def decrement(player_id) = connection_map.decrement_by(player_id, 1)

  private

  # @dynamic connection_map
  attr_reader :connection_map
end
