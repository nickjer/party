# frozen_string_literal: true

module LoadedQuestions
  class Player
    def initialize(player)
      @player = player
    end

    def active? = document.fetch(:active)

    private

    # @dynamic player
    attr_reader :player

    def document = player.parsed_document #: document
  end
end
