# frozen_string_literal: true

module LoadedQuestions
  class NewGame
    def initialize(user:, player_name:, question:, hide_answers:)
      @player = NewPlayer.new(user:, name: player_name, guesser: true)
      @question = question
      @hide_answers = hide_answers.present?
    end

    def build
      game = ::Game.new
      game.kind = :loaded_questions
      game.document = document.to_json
      game.players = [ player.build ]
      game.slug = ::SecureRandom.alphanumeric(6)
      game
    end

    private

    # @dynamic hide_answers
    attr_reader :hide_answers

    # @dynamic player
    attr_reader :player

    # @dynamic question
    attr_reader :question

    def document
      {
        hide_answers:,
        question: question.to_s,
        status: :polling.to_s
      }
    end
  end
end
