# frozen_string_literal: true

module LoadedQuestions
  # Builder object for starting a new round in an existing game
  class CreateNewRound
    def initialize(game:, guesser:, question:)
      @game = game
      @guesser = guesser
      @question = question
    end

    def call
      game.guesses = Game::Guesses.empty
      game.question = question
      game.status = Game::Status.polling

      # Clear out player answers and set new guesser
      game.players.each do |player|
        player.reset_answer
        player.guesser = (player.id == guesser.id)
      end

      game
    end

    private

    # @dynamic game, guesser, question
    attr_reader :game, :guesser, :question
  end
end
