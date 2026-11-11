# frozen_string_literal: true

module BurnUnit
  # Readiness check for tallying the round: enough votes must be in. Status
  # and role are the aggregate's concern.
  class CompletedRoundForm
    # @dynamic errors
    attr_reader :errors

    def initialize(game:)
      @game = game
      @errors = Errors.new
    end

    def valid?
      vote_count = game.players.count(&:voted?)
      if vote_count < 2
        errors.add(:base,
          message: "Need at least 2 votes to tally (currently #{vote_count})")
      end

      errors.empty?
    end

    private

    # @dynamic game
    attr_reader :game
  end
end
