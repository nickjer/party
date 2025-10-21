# frozen_string_literal: true

module LoadedQuestions
  # Wrapper around ::Player model that provides Loaded Questions-specific
  # behavior and document parsing.
  class Player
    MIN_ANSWER_LENGTH = 3
    MAX_ANSWER_LENGTH = 80

    def initialize(model) = @model = model

    def <=>(other) = name <=> other.name

    def ==(other) = self.class == other.class && id == other.id

    def answer = @answer ||= NormalizedString.new(json_document.fetch(:answer))

    def answer=(new_answer)
      validate_between!(
        new_answer,
        min: MIN_ANSWER_LENGTH,
        max: MAX_ANSWER_LENGTH,
        field: :answer
      )

      @answer = new_answer
      update_model_document
    end

    def answered? = answer.present?

    def eql?(other) = self == other

    def game_id = model.game_id

    def guesser? = json_document.fetch(:guesser)

    def hash = id.hash

    def id = model.id

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

    def save!
      model.save! if model.changed?
    end

    def score = @score ||= json_document.fetch(:score)

    def score=(new_score)
      raise ArgumentError, "Score cannot be negative" if new_score.negative?

      @score = new_score
      update_model_document
    end

    def to_model = model

    def user = model.user

    private

    # @dynamic model
    attr_reader :model

    def json_document = model.parsed_document #: json_document

    def update_model_document
      # @type var new_document: document
      new_document = { answer:, guesser: guesser?, score: }
      model.document = new_document.to_json
    end

    def validate_between!(value, min:, max:, field:)
      return if value.length.between?(min, max)

      raise ArgumentError, "#{field.to_s.humanize} length must be " \
        "between #{min} and #{max} characters"
    end
  end
end
