# frozen_string_literal: true

module LoadedQuestions
  # Builder object for constructing new Loaded Questions games with initial
  # player and question.
  class CreateNewGame
    def initialize(user:, player_name:, question:)
      @user = user
      @player_name = player_name
      @question = question
    end

    def call
      game = ::Game.new
      game.kind = :loaded_questions
      game.document = document.to_json
      game.id = ::Game.generate_unique_id

      ::Game.transaction do
        game.save!

        CreateNewPlayer.new(
          game_id: game.id,
          user:,
          name: player_name,
          guesser: true
        ).call
      end

      game
    end

    private

    # @dynamic user
    attr_reader :user

    # @dynamic player_name
    attr_reader :player_name

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
