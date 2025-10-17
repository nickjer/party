# frozen_string_literal: true

module LoadedQuestions
  # Form object for validating transition from guessing to completed phase.
  class CompletedRoundForm
    # @dynamic errors
    attr_reader :errors

    def initialize(game:)
      @game = game
      @errors = []
    end

    def valid?
      errors << "Game is not in guessing phase" unless game.status.guessing?

      errors.empty?
    end

    private

    # @dynamic game
    attr_reader :game
  end
end
