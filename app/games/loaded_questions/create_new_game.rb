# frozen_string_literal: true

module LoadedQuestions
  # Builder object for constructing new Loaded Questions games with initial
  # player and question.
  class CreateNewGame
    def initialize(user_id:, player_name:, question:)
      @user_id = user_id
      @player_name = player_name
      @question = question
    end

    def call
      game = Game.build(question:)
      game.add_player(user_id:, name: player_name, guesser: true)
      game
    end

    private

    # @dynamic player_name, question, user_id
    attr_reader :player_name, :question, :user_id
  end
end
