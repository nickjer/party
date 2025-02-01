# frozen_string_literal: true

module LoadedQuestions
  class Game
    def initialize(game)
      @game = game
    end

    def guesser_id = document.fetch(:guesser_id)

    def players = game.players.map { |player| Player.new(player) }

    private

    # @dynamic game
    attr_reader :game

    def document = game.parsed_document #: document
  end
end
