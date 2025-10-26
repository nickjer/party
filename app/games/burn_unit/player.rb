# frozen_string_literal: true

module BurnUnit
  # Wrapper around ::Player model that provides Burn Unit-specific
  # behavior and document parsing.
  class Player
    class << self
      def build(game_id:, user_id:, name:, judge: false, playing: false)
        document = {
          judge:,
          score: 0,
          vote: nil,
          playing:
        } #: document
        player =
          new(::Player.new(game_id:, user_id:, document: document.to_json))
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

    def judge?
      return @judge if defined?(@judge)

      @judge = json_document.fetch(:judge)
    end

    def judge=(is_judge)
      @judge = is_judge
      model.document = document.to_json
    end

    def name = NormalizedString.new(model.name)

    def name=(new_name)
      validate_between!(
        new_name,
        min: ::Player::MIN_NAME_LENGTH,
        max: ::Player::MAX_NAME_LENGTH,
        field: :name
      )
      model.name = new_name.to_s
    end

    def online? = model.online?

    def playing?
      return @playing if defined?(@playing)

      @playing = json_document.fetch(:playing)
    end

    def playing=(is_playing)
      @playing = is_playing
      model.document = document.to_json
    end

    def save!
      model.save! if model.changed?
    end

    def score = @score ||= json_document.fetch(:score)

    def score=(new_score)
      raise ArgumentError, "Score cannot be negative" if new_score.negative?

      @score = new_score
      model.document = document.to_json
    end

    def to_model = model

    def user_id = model.user_id

    def vote
      return @vote if defined?(@vote)

      @vote = json_document.fetch(:vote)
    end

    def vote=(player_id)
      @vote = player_id
      model.document = document.to_json
    end

    def voted? = vote.present?

    private

    # @dynamic model
    attr_reader :model

    def document = { judge: judge?, score:, vote:, playing: playing? }

    def json_document = model.parsed_document #: json_document

    def validate_between!(value, min:, max:, field:)
      return if value.length.between?(min, max)

      raise ArgumentError, "#{field.to_s.humanize} length must be " \
        "between #{min} and #{max} characters"
    end
  end
end
