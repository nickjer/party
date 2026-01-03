# frozen_string_literal: true

module LoadedQuestions
  # Wrapper around ::Game model that provides Loaded Questions-specific
  # behavior and document parsing.
  class Game
    MIN_QUESTION_LENGTH = 3
    MAX_QUESTION_LENGTH = 160

    class << self
      def build(question:)
        document = {
          question: NormalizedString.new(""),
          guesses: Guesses.empty,
          status: Status.polling
        } #: document
        game =
          new(::Game.new(kind: :loaded_questions, document: document.to_json))
        game.question = question
        game
      end

      def find(id) = new(scope.find(id))

      private

      def scope
        ::Game.strict_loading.loaded_questions.includes(:players)
      end
    end

    def initialize(model)
      @model = model
    end

    def find_player(id)
      players.find { |player| player.id == id } || raise("Player not found")
    end

    def guesser
      players.find(&:guesser?) || raise("Couldn't find guesser")
    end

    def guesses
      @guesses ||= Guesses.parse(json_document.fetch(:guesses), players:)
    end

    def guesses=(new_guesses)
      @guesses = new_guesses
      model.document = document.to_json
    end

    def id = model.id

    def player_for!(user_id)
      player_for(user_id) ||
        raise(ActiveRecord::RecordNotFound, "Couldn't find Player")
    end

    def player_for(user_id)
      players.find { |player| player.user_id == user_id }
    end

    def players = cached_players.sort

    def question
      @question ||= NormalizedString.new(json_document.fetch(:question))
    end

    def question=(new_question)
      validate_between!(
        new_question,
        min: MIN_QUESTION_LENGTH,
        max: MAX_QUESTION_LENGTH,
        field: :question
      )

      @question = new_question
      model.document = document.to_json
    end

    def save!
      ::Game.transaction do
        model.save! if model.changed?
        players.each(&:save!)
      end
    end

    def status
      @status ||= Status.parse(json_document.fetch(:status))
    end

    def status=(new_status)
      @status = new_status
      model.document = document.to_json
    end

    def to_model = model

    def add_player(user_id:, name:, guesser: false)
      raise "Player already exists for user" if player_for(user_id)

      player = Player.build(game_id: id, user_id:, name:, guesser:)
      cached_players << player
      player
    end

    def assign_guess(player_id:, answer_id:)
      self.guesses = guesses.assign(player_id:, answer_id:)
    end

    private

    # @dynamic model
    attr_reader :model

    def cached_players
      @cached_players ||= model.players.map { |player| Player.new(player) }
    end

    def document = { question:, guesses:, status: }

    def json_document = model.parsed_document #: json_document

    def validate_between!(value, min:, max:, field:)
      return if value.length.between?(min, max)

      raise ArgumentError, "#{field.to_s.humanize} length must be " \
        "between #{min} and #{max} characters"
    end
  end
end
