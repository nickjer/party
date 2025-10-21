# frozen_string_literal: true

module LoadedQuestions
  # Service object for transitioning game from guessing to completed status.
  # Updates guesser's score based on correct guesses.
  class CompleteRound
    def initialize(game:)
      @game = game
    end

    def call
      raise "Game must be in guessing status" unless game.status.guessing?

      # Update guesser's score by adding the number of correct guesses
      round_score = game.guesses.score
      current_guesser = game.guesser
      new_total_score = current_guesser.score + round_score
      current_guesser.score = new_total_score

      game.status = Game::Status.completed

      game
    end

    private

    # @dynamic game
    attr_reader :game
  end
end
