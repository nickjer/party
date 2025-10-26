# frozen_string_literal: true

module BurnUnit
  # Service object for completing a round and awarding points to winners
  class CompleteRound
    def initialize(game:)
      @game = game
    end

    def call
      raise "Game must be in polling status" unless game.status.polling?

      game.candidates.each do |candidate|
        candidate.player.score += 1 if candidate.winner?
      end

      game.status = Game::Status.completed

      game
    end

    private

    # @dynamic game
    attr_reader :game
  end
end
