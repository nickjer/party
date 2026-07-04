# frozen_string_literal: true

module BurnUnit
  # Aggregate for a Burn Unit game. Persistence goes through GameRepo.
  # Identity methods delegate to GlobalIdentity for Rails interop.
  class Game
    QUESTION_LENGTH = LengthValidator.new(min: 3, max: 160, field: :question)

    class << self
      def build(question:, id: nil)
        id ||= GameStore.generate_game_id
        document = Document.new(question: question, status: Status.polling)
        new(id:, document:, players: [])
      end
    end

    # @dynamic id
    attr_reader :id

    def initialize(id:, document:, players:)
      @id = id
      @identity = GlobalIdentity.new(model: ::Game, id:)
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

    def status = document.status

    def complete_round
      raise "Game must be in polling status" unless status.polling?

      candidates.each do |candidate|
        candidate.player.score += 1 if candidate.winner?
      end
      @document = document.with(status: Status.completed)
      self
    end

    def start_new_round(question:, judge:)
      raise "Game must be in completed status" unless status.completed?

      @document = document.with(question:, status: Status.polling)
      players.each do |player|
        player.vote = nil
        player.judge = (player == judge)
        player.playing = player.online? || player.judge?
      end
      self
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
