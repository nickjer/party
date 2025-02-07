# frozen_string_literal: true

class ScoreMap
  def initialize
    @score_map = Concurrent::Map.new
  end

  def increment_by(key, new_score)
    score_map.compute(key) { |old_score| (old_score || 0) + new_score }
  end

  def decrement_by(key, new_score)
    score_map.compute(key) do |old_score|
      new_score = (old_score || 0) - new_score
      new_score.positive? ? new_score : 0
    end
  end

  def score(key) = score_map.fetch(key, 0)

  private

  # @dynamic score_map
  attr_reader :score_map
end
