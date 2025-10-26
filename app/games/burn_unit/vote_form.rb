# frozen_string_literal: true

module BurnUnit
  # Form object for validating player votes during the polling phase.
  class VoteForm
    # @dynamic candidate_id
    attr_reader :candidate_id

    # @dynamic current_player
    attr_reader :current_player

    # @dynamic game
    attr_reader :game

    # @dynamic errors
    attr_reader :errors

    def initialize(game:, current_player:, candidate_id: nil)
      @game = game
      @current_player = current_player
      @candidate_id = candidate_id
      @errors = Errors.new
    end

    def available_candidates
      game.candidates.map(&:player).without(current_player)
    end

    def game_id = game.id

    def show? = candidate_id.blank? || !errors.empty?

    def valid?
      if candidate_id.blank?
        errors.add(:candidate_id, message: "must be selected")
        return false
      end

      candidate = game.candidates.find { |player| player.id == candidate_id }
      if candidate.nil?
        errors.add(:candidate_id, message: "is not a valid candidate")
      end

      if candidate_id == current_player.id
        errors.add(:candidate_id, message: "cannot vote for yourself")
      end

      errors.empty?
    end
  end
end
