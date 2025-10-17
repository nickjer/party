# frozen_string_literal: true

module LoadedQuestions
  # Builder object for constructing new Loaded Questions games with initial
  # player and question.
  class NewGame
    def initialize(user:, player_name:, question:)
      @player = NewPlayer.new(user:, name: player_name, guesser: true)
      @question = question
    end

    def build
      game = ::Game.new
      game.kind = :loaded_questions
      game.document = document.to_json
      game.players = [player.build]
      game.slug = ::SecureRandom.alphanumeric(6)
      game
    end

    private

    # @dynamic player
    attr_reader :player

    # @dynamic question
    attr_reader :question

    def document
      {
        question: question.to_s,
        guesses: [],
        status: :polling.to_s
      }
    end
  end
end
