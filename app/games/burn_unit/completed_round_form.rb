# frozen_string_literal: true

module BurnUnit
  # Form object for validating transition from polling to completed phase.
  class CompletedRoundForm
    # @dynamic errors
    attr_reader :errors

    def initialize(game:)
      @game = game
      @errors = Errors.new
    end

    def valid?
      unless game.status.polling?
        errors.add(:base, message: "Game is not in polling phase")
      end

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
