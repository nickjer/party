# frozen_string_literal: true

module LoadedQuestions
  # Aggregate for a Loaded Questions player. Persistence goes through GameRepo
  # (via the parent game). Identity methods delegate to GlobalIdentity.
  class Player
    ANSWER_LENGTH = LengthValidator.new(min: 3, max: 80, field: :answer)

    class << self
      def build(game_id:, user_id:, name:, guesser: false, id: nil)
        id ||= GameStore.generate_player_id
        document = Document.new(
          answer: Answer.empty,
          guesser: guesser,
          score: 0
        )
        new(id:, game_id:, user_id:, name:, document:)
      end
    end

    # @dynamic id, game_id, user_id
    attr_reader :id, :game_id, :user_id

    def initialize(id:, game_id:, user_id:, name:, document:)
      @id = id
      @identity = GlobalIdentity.new(model: ::Player, id:)
      @game_id = game_id
      @user_id = user_id
      @name = name
      @document = document
    end

    def <=>(other) = name <=> other.name

    def ==(other) = self.class == other.class && id == other.id

    def answer = document.answer

    def answer=(new_answer)
      ANSWER_LENGTH.validate!(new_answer.value)
      @document = document.with(answer: new_answer)
    end

    def answered? = answer.present?

    def eql?(other) = self == other

    def guesser? = document.guesser

    def guesser=(is_guesser)
      @document = document.with(guesser: is_guesser)
    end

    def hash = id.hash

    # @dynamic name, name=
    attr_accessor :name

    def online? = PlayerConnections.instance.count(id).positive?

    def reset_answer
      @document = document.with(answer: Answer.empty)
    end

    def score = document.score

    def score=(new_score)
      @document = document.with(score: new_score)
    end

    def document_json = document.to_json

    def model_name = identity.model_name
    def to_key = identity.to_key
    def to_param = identity.to_param
    def to_global_id(options = {}) = identity.to_global_id(options)
    def to_gid_param(options = {}) = identity.to_gid_param(options)

    private

    # @dynamic document, identity
    attr_reader :document, :identity
  end
end
