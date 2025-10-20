# frozen_string_literal: true

module LoadedQuestions
  # Wrapper around ::Player model that provides Loaded Questions-specific
  # behavior and document parsing.
  class Player
    def initialize(player, game:)
      @player = player
      @game = game
    end

    def <=>(other) = name <=> other.name

    def ==(other) = self.class == other.class && id == other.id

    def active? = document.fetch(:active)

    def answer = NormalizedString.new(document.fetch(:answer))

    def answered? = answer.present?

    def eql?(other) = self == other

    def guesser? = document.fetch(:guesser)

    def hash = id.hash

    def id = player.id

    def name = player.name

    def online? = player.online?

    def game_slug = game.slug

    def score = document.fetch(:score)

    def to_model = player

    def update_answer(answer)
      document[:answer] = answer.to_s
      player.document = document.to_json
      player.save!
    end

    def update_name(name)
      player.name = name.to_s
      player.save!
    end

    def update_score(new_score)
      document[:score] = new_score
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
