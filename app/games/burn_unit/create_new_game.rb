# frozen_string_literal: true

module BurnUnit
  # Builder object for constructing new Burn Unit games with initial
  # player (judge) and question.
  class CreateNewGame
    def initialize(user_id:, player_name:, question:)
      @user_id = user_id
      @player_name = player_name
      @question = question
    end

    def call
      game = Game.build(question:)
      game.add_player(user_id:, name: player_name, judge: true, playing: true)
      game
    end

    private

    # @dynamic player_name, question, user_id
    attr_reader :player_name, :question, :user_id
  end
end
