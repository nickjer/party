# frozen_string_literal: true

module LoadedQuestions
  class Player
    def initialize(player, game:)
      @player = player
      @game = game
    end

    def <=>(other) = player.name <=> other.name

    def active? = document.fetch(:active)

    def answer = NormalizedString.new(document.fetch(:answer))

    def guesser? = document.fetch(:guesser)

    def id = player.id

    def name = player.name

    def update_answer(answer)
      document[:answer] = answer.to_s
      player.document = document.to_json
      player.save!
    end

    def user = player.user

    private

    # @dynamic game
    attr_reader :game

    # @dynamic player
    attr_reader :player

    def document = player.parsed_document #: document
  end
end
