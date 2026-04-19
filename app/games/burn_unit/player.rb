# frozen_string_literal: true

module BurnUnit
  # Wrapper around ::Player model that provides Burn Unit-specific
  # behavior and document parsing.
  class Player
    class << self
      def build(game_id:, user_id:, name:, judge: false, playing: false)
        document = Document.new(
          judge: judge, score: 0, vote: nil, playing: playing
        )
        player = new(
          ::Player.new(
            game_id: game_id, user_id: user_id, document: document.to_json
          )
        )
        player.name = name
        player
      end
    end

    def initialize(model) = @model = model

    def <=>(other) = name <=> other.name

    def ==(other) = self.class == other.class && id == other.id

    def eql?(other) = self == other

    def game_id = model.game_id

    def hash = id.hash

    def id = model.id

    def judge? = document.judge

    def judge=(is_judge)
      @document = document.with(judge: is_judge)
    end

    def name = NormalizedString.new(model.name)

    def name=(new_name)
      ::Player::NAME_LENGTH.validate!(new_name)
      model.name = new_name.to_s
    end

    def online? = model.online?

    def playing? = document.playing

    def playing=(is_playing)
      @document = document.with(playing: is_playing)
    end

    def save!
      model.document = document.to_json
      model.save! if model.changed?
    end

    def score = document.score

    def score=(new_score)
      @document = document.with(score: new_score)
    end

    def to_model = model

    def user_id = model.user_id

    def vote = document.vote

    def vote=(player_id)
      @document = document.with(vote: player_id)
    end

    def voted? = vote.present?

    private

    # @dynamic model
    attr_reader :model

    def document
      parsed_document = model.parsed_document #: Document::json
      @document ||= Document.parse(parsed_document)
    end
  end
end
