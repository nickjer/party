# frozen_string_literal: true

module LoadedQuestions
  class NewPlayer
    def initialize(name:, guesser:)
      @name = NormalizedString.new(name)
      @guesser = guesser
    end

    def build
      player = ::Player.new
      player.name = name
      player.document = document.to_json
      player
    end

    private

    # @dynamic guesser
    attr_reader :guesser

    # @dynamic name
    attr_reader :name

    def document
      {
        active: true,
        answer: "",
        guesser:
      }
    end
  end
end
