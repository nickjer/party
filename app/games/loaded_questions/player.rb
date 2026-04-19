# frozen_string_literal: true

module LoadedQuestions
  # Wrapper around ::Player model that provides Loaded Questions-specific
  # behavior and document parsing.
  class Player
    ANSWER_LENGTH = LengthValidator.new(min: 3, max: 80, field: :answer)

    class << self
      def build(game_id:, user_id:, name:, guesser: false)
        document = Document.new(
          answer: Answer.empty,
          guesser: guesser,
          score: 0
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

    def answer = document.answer

    def answer=(new_answer)
      ANSWER_LENGTH.validate!(new_answer.value)
      @document = document.with(answer: new_answer)
    end

    def answered? = answer.present?

    def eql?(other) = self == other

    def game_id = model.game_id

    def guesser? = document.guesser

    def guesser=(is_guesser)
      @document = document.with(guesser: is_guesser)
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
      @document = document.with(answer: Answer.empty)
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

    private

    # @dynamic model
    attr_reader :model

    def document
      parsed_document = model.parsed_document #: Document::json
      @document ||= Document.parse(parsed_document)
    end
  end
end
