# frozen_string_literal: true

module LoadedQuestions
  class Player
    def initialize(player, game:)
      @player = player
      @game = game
    end

    def active? = document.fetch(:active)

    def answer = NormalizedString.new(document.fetch(:answer))

    def guesser? = document.fetch(:guesser)

    def name = player.name

    def user = player.user

    private

    # @dynamic game
    attr_reader :game

    # @dynamic player
    attr_reader :player

    def document = player.parsed_document #: document
  end
end
