# frozen_string_literal: true

module LoadedQuestions
  class Player
    def initialize(player, game:)
      @player = player
      @game = game
    end

    def active? = document.fetch(:active)

    def answer = NormalizedString.new(document.fetch(:answer))

    def guesser? = game.guesser_id == player.id

    private

    # @dynamic game
    attr_reader :game

    # @dynamic player
    attr_reader :player

    def document = player.parsed_document #: document
  end
end
