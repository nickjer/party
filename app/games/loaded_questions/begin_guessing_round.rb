# frozen_string_literal: true

module LoadedQuestions
  # Service object for transitioning game from polling to guessing status.
  # Creates unassigned guesses for all answered players.
  class BeginGuessingRound
    def initialize(game:)
      @game = game
    end

    def call
      raise "Game must be in polling status" unless game.status.polling?

      participants = game.players.select(&:answered?)
      guesses = participants.map do |player|
        Game::GuessedAnswer.new(player:, guessed_player: nil)
      end

      game.guesses = Game::Guesses.new(guesses:)
      game.status = Game::Status.guessing

      game
    end

    private

    # @dynamic game
    attr_reader :game
  end
end
