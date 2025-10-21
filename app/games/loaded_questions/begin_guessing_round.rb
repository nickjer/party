# frozen_string_literal: true

module LoadedQuestions
  # Service object for transitioning game from polling to guessing status.
  # Shuffles answered players and creates guess pairs.
  class BeginGuessingRound
    def initialize(game:)
      @game = game
    end

    def call
      raise "Game must be in polling status" unless game.status.polling?

      participants = game.players.select(&:answered?)
      shuffled_participants = participants.shuffle

      guesses =
        participants.zip(shuffled_participants)
          .map do |player, guessed_player|
            raise "Guessed player is missing" unless guessed_player

            Game::GuessedAnswer.new(player:, guessed_player:)
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
