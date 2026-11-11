# frozen_string_literal: true

module LoadedQuestions
  # Readiness check for opening the guessing phase: enough players must have
  # answered. Status and role are the aggregate's concern.
  class GuessingRoundForm
    MIN_ANSWERED = 2

    # @dynamic errors
    attr_reader :errors

    def initialize(game:)
      @game = game
      @errors = Errors.new
    end

    def valid?
      if game.players.count(&:answered?) < MIN_ANSWERED
        message =
          "Not enough players have answered (need at least #{MIN_ANSWERED})"
        errors.add(:base, message:)
      end

      errors.empty?
    end

    private

    # @dynamic game
    attr_reader :game
  end
end
