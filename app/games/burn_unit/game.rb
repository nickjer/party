# frozen_string_literal: true

module BurnUnit
  # Wrapper around ::Game model that provides Burn Unit-specific
  # behavior and document parsing.
  class Game
    QUESTION_LENGTH = LengthValidator.new(min: 3, max: 160, field: :question)

    class << self
      def build(question:)
        document = Document.new(question: question, status: Status.polling)
        new(
          ::Game.new(kind: :burn_unit, document: document.to_json)
        )
      end

      def find(id) = new(scope.find(id))

      private

      def scope = ::Game.strict_loading.burn_unit.includes(:players)
    end

    def initialize(model) = @model = model

    def add_player(user_id:, name:, judge: false, playing: false)
      raise "Player already exists for user" if player_for(user_id)

      player = Player.build(game_id: id, user_id:, name:, judge:, playing:)
      cached_players << player
      player
    end

    def candidates = Candidate.from(players.select(&:playing?))

    def find_player(id)
      players.find { |player| player.id == id } || raise("Player not found")
    end

    def id = model.id

    def judge = players.find(&:judge?) || raise("Couldn't find judge")

    def player_for(user_id)
      players.find { |player| player.user_id == user_id }
    end

    def player_for!(user_id)
      player_for(user_id) ||
        raise(ActiveRecord::RecordNotFound, "Couldn't find Player")
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
