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
      game = Game.build(question:)
      game.add_player(user_id: user.id, name: player_name, guesser: true)
      game
    end

    private

    # @dynamic user
    attr_reader :user

    # @dynamic player_name
    attr_reader :player_name

    # @dynamic question
    attr_reader :question
  end
end
