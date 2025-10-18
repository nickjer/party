# frozen_string_literal: true

module LoadedQuestions
  # Form object for validating transition from polling to guessing phase.
  class GuessingRoundForm
    MIN_ANSWERED = 2

    # @dynamic errors
    attr_reader :errors

    def initialize(game:)
      @game = game
      @errors = Errors.new
    end

    def valid?
      unless game.status.polling?
        errors.add(:base, message: "Game is not polling")
      end

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
