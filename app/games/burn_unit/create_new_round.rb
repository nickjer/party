# frozen_string_literal: true

module BurnUnit
  # Builder object for starting a new round in an existing game
  class CreateNewRound
    def initialize(game:, judge:, question:)
      @game = game
      @judge = judge
      @question = question
    end

    def call
      game.question = question
      game.status = Game::Status.polling

      # Clear out player votes, set new judge, and set online players as playing
      game.players.each do |player|
        player.vote = nil
        player.judge = (player == judge)
        player.playing = player.online? || player.judge?
      end

      game
    end

    private

    # @dynamic game, judge, question
    attr_reader :game, :judge, :question
  end
end
