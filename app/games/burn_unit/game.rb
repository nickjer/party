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
      reject "Player already exists for user" if player_for(user_id)

      player = Player.build(game_id: id, user_id:, name:, judge:, playing:)
      @players << player
      player
    end

    def candidates = Candidate.from(players.select(&:playing?))

    def find_player(id)
      players.find { |player| player.id == id } ||
        reject("Player not found")
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

    # Guards: raise Rejected unless the player may do that right now (status
    # and role). The operation calls its guard itself; controllers call it
    # before building a form so a stale request is refused, not shown errors.

    # Only the judge may close the round and award the winner.
    def check_complete_round(player)
      reject "Game must be in polling status" unless status.polling?
      reject "Only the judge can complete the round" unless player.judge?
    end

    # The next round is opened by its judge, who may not be the current one.
    def check_start_new_round(player)
      reject "Game must be in completed status" unless status.completed?
      reject "The judge cannot open the next round" if player.judge?
    end

    # Viewing the poll enters the viewer as a candidate. A page view triggers
    # it, so it never rejects: returns the player when newly entered, else nil.
    def enter_poll(player)
      return nil unless status.polling?
      return nil if player.playing?

      player.playing = true
      player
    end

    def complete_round(player:)
      check_complete_round(player)

      candidates.each do |candidate|
        candidate.player.score += 1 if candidate.winner?
      end
      @document = document.with(status: Status.completed)
      self
    end

    def start_new_round(question:, judge:)
      check_start_new_round(judge)

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

    def reject(message) = raise(GameStore::Rejected, message)
  end
end
