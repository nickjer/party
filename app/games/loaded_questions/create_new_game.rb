# frozen_string_literal: true

module LoadedQuestions
  # Builder object for constructing new Loaded Questions games with initial
  # player and question.
  class CreateNewGame
    def initialize(user:, player_name:, question:)
      @player = NewPlayer.new(user:, name: player_name, guesser: true)
      @question = question
    end

    def call
      game = ::Game.new
      game.kind = :loaded_questions
      game.document = document.to_json
      game.players = [player.build]
      game.slug = ::SecureRandom.alphanumeric(6)
      game.save!
      game
    end

    private

    # @dynamic player
    attr_reader :player

    # @dynamic question
    attr_reader :question

    def document
      {
        guesses: Game::Guesses.new(guesses: []),
        question: question,
        status: Game::Status.polling
      }
    end
  end
end
