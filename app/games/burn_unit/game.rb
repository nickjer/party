# frozen_string_literal: true

module BurnUnit
  # Aggregate for a Burn Unit game. Persistence goes through GameRepo.
  # Identity methods delegate to ::Game for Rails interop (dom_id, GlobalID).
  class Game
    QUESTION_LENGTH = LengthValidator.new(min: 3, max: 160, field: :question)

    class << self
      def build(question:, id: nil)
        id ||= GameRepo.generate_id
        document = Document.new(question: question, status: Status.polling)
        new(id:, document:, players: [])
      end
    end

    # @dynamic id
    attr_reader :id

    def initialize(id:, document:, players:)
      @id = id
      @document = document
      @players = players
    end

    def add_player(user_id:, name:, judge: false, playing: false)
      raise "Player already exists for user" if player_for(user_id)

      player = Player.build(game_id: id, user_id:, name:, judge:, playing:)
      @players << player
      player
    end

    def candidates = Candidate.from(players.select(&:playing?))

    def find_player(id)
      players.find { |player| player.id == id } || raise("Player not found")
    end

    def judge = players.find(&:judge?) || raise("Couldn't find judge")

    def player_for(user_id)
      players.find { |player| player.user_id == user_id }
    end

    def player_for!(user_id)
      player_for(user_id) ||
        raise(ActiveRecord::RecordNotFound, "Couldn't find Player")
    end

    def players = @players.sort

    def question = document.question

    def question=(new_question)
      @document = document.with(question: new_question)
    end

    def status = document.status

    def status=(new_status)
      @document = document.with(status: new_status)
    end

    def document_json = document.to_json

    def model_name = ::Game.model_name
    def to_key = [id]
    def to_param = id

    def to_global_id(options = {})
      GlobalID.new(URI::GID.build(
        app: options.fetch(:app) { GlobalID.app },
        model_name: "Game",
        model_id: id,
        params: options.except(:app, :verifier, :for)
      ))
    end

    def to_gid_param(options = {}) = to_global_id(options).to_param

    private

    # @dynamic document
    attr_reader :document
  end
end
