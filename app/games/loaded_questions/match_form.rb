# frozen_string_literal: true

module LoadedQuestions
  class MatchForm
    MIN_ANSWERED = 2

    # @dynamic errors
    attr_reader :errors

    def initialize(game:)
      @game = game
      @errors = []
    end

    def valid?
      errors << "Game is not polling" unless game.status.polling?

      if game.players.count(&:answered?) < MIN_ANSWERED
        errors <<
          "Not enough players have answered (need at least #{MIN_ANSWERED})"
      end

      errors.empty?
    end

    private

    # @dynamic game
    attr_reader :game
  end
end
