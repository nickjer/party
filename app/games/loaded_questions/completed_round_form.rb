# frozen_string_literal: true

module LoadedQuestions
  # Readiness check for completing the round: every answer must be assigned.
  # Status and role are the aggregate's concern.
  class CompletedRoundForm
    # @dynamic errors
    attr_reader :errors

    def initialize(game:)
      @game = game
      @errors = Errors.new
    end

    def valid?
      unless game.guesses.complete?
        errors.add(:base, message: "All answers must be assigned to players")
      end

      errors.empty?
    end

    private

    # @dynamic game
    attr_reader :game
  end
end
