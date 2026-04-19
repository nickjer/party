# frozen_string_literal: true

module LoadedQuestions
  # Wrapper around ::Player model that provides Loaded Questions-specific
  # behavior and document parsing.
  class Player
    ANSWER_LENGTH = LengthValidator.new(min: 3, max: 80, field: :answer)

    class << self
      def build(game_id:, user_id:, name:, guesser: false)
        document = {
          answer: Answer.empty,
          guesser:,
          score: 0
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

    def answer = @answer ||= Answer.parse(json_document.fetch(:answer))

    def answer=(new_answer)
      ANSWER_LENGTH.validate!(new_answer.value)

      @answer = new_answer
      model.document = document.to_json
    end

    def answered? = answer.present?

    def eql?(other) = self == other

    def game_id = model.game_id

    def guesser?
      return @guesser if defined?(@guesser)

      @guesser = json_document.fetch(:guesser)
    end

    def guesser=(is_guesser)
      @guesser = is_guesser
      model.document = document.to_json
    end

    def hash = id.hash

    def id = model.id

    def name = NormalizedString.new(model.name)

    def name=(new_name)
      ::Player::NAME_LENGTH.validate!(new_name)
      model.name = new_name.to_s
    end

    def online? = model.online?

    def reset_answer
      @answer = Answer.empty
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

    private

    # @dynamic model
    attr_reader :model

    def document = { answer:, guesser: guesser?, score: }

    def json_document = model.parsed_document #: json_document
  end
end
