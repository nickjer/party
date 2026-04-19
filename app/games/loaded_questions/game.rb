# frozen_string_literal: true

module LoadedQuestions
  # Wrapper around ::Game model that provides Loaded Questions-specific
  # behavior and document parsing.
  class Game
    QUESTION_LENGTH = LengthValidator.new(min: 3, max: 160, field: :question)

    class << self
      def build(question:)
        document = Document.new(
          question: question,
          status: Status.polling,
          guesses_data: []
        )
        new(
          ::Game.new(kind: :loaded_questions, document: document.to_json)
        )
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
      @guesses ||= Guesses.parse(document.guesses_data, players:)
    end

    def guesses=(new_guesses)
      @guesses = new_guesses
      @document = document.with(guesses_data: new_guesses.map(&:to_h))
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

    def question = document.question

    def question=(new_question)
      @document = document.with(question: new_question)
    end

    def save!
      ::Game.transaction do
        model.document = document.to_json
        model.save! if model.changed?
        players.each(&:save!)
      end
    end

    def status = document.status

    def status=(new_status)
      @document = document.with(status: new_status)
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

    def document
      parsed_document = model.parsed_document #: Document::json
      @document ||= Document.parse(parsed_document)
    end
  end
end
