# frozen_string_literal: true

module LoadedQuestions
  class Player
    def initialize(player, game:)
      @player = player
      @game = game
    end

    def <=>(other) = name <=> other.name

    def ==(other) = self.class == other.class && id == other.id

    def active? = document.fetch(:active)

    def answer = NormalizedString.new(document.fetch(:answer))

    def answered? = !answer.blank?

    def eql?(other) = self == other

    def guesser? = document.fetch(:guesser)

    def hash = id.hash

    def id = player.id

    def name = player.name

    def online? = player.online?

    def update_answer(answer)
      document[:answer] = answer.to_s
      player.document = document.to_json
      player.save!
    end

    def user = player.user

    def to_gid_param = player.to_gid_param

    private

    # @dynamic game
    attr_reader :game

    # @dynamic player
    attr_reader :player

    def document = player.parsed_document #: document
  end
end
