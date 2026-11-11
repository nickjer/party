# frozen_string_literal: true

module LoadedQuestions
  # Aggregate for a Loaded Questions game. Persistence goes through GameRepo.
  # Identity methods delegate to GlobalIdentity for Rails interop.
  class Game
    QUESTION_LENGTH = LengthValidator.new(min: 3, max: 160, field: :question)

    class << self
      def build(question:, id: nil)
        id ||= GameStore.generate_game_id
        document = Document.new(
          question: question,
          status: Status.polling,
          guesses_data: []
        )
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
      @guesses = Guesses.parse(document.guesses_data, players:)
    end

    def find_player(id)
      players.find { |player| player.id == id } ||
        reject("Player not found")
    end

    def guesser
      players.find(&:guesser?) || raise("Couldn't find guesser")
    end

    # @dynamic guesses
    attr_reader :guesses

    def player_for!(user_id)
      player_for(user_id) ||
        raise(ActiveRecord::RecordNotFound, "Couldn't find Player")
    end

    def player_for(user_id)
      players.find { |player| player.user_id == user_id }
    end

    def players = @players.sort

    def question = document.question

    def status = document.status

    def add_player(user_id:, name:, guesser: false)
      reject "Player already exists for user" if player_for(user_id)

      player = Player.build(game_id: id, user_id:, name:, guesser:)
      @players << player
      player
    end

    # Guards: raise Rejected unless the player may do that right now (status
    # and role). The operation calls its guard itself; controllers call it
    # before building a form so a stale request is refused, not shown errors.

    def check_begin_guessing(player)
      reject "Game must be in polling status" unless status.polling?
      reject "Only the guesser can begin guessing" unless player.guesser?
    end

    def check_complete_round(player)
      reject "Game must be in guessing status" unless status.guessing?
      reject "Only the guesser can complete the round" unless player.guesser?
    end

    # The next round's guesser is whoever opens it; the current guesser may not.
    def check_start_new_round(player)
      reject "Game must be in completed status" unless status.completed?
      reject "The guesser cannot open the next round" if player.guesser?
    end

    def assign_guess(player:, player_id:, answer_id:)
      reject "Game must be in guessing status" unless status.guessing?
      reject "Only the guesser can assign guesses" unless player.guesser?

      @guesses = guesses.assign(player_id:, answer_id:)
      @document = document.with(guesses_data: @guesses.map(&:to_h))
    end

    def begin_guessing(player:)
      check_begin_guessing(player)

      answered = players.select(&:answered?)
      new_guesses = answered.map do |player|
        GuessedAnswer.new(player:, guessed_player: nil)
      end
      @guesses = Guesses.new(guesses: new_guesses)
      @document = document.with(
        status: Status.guessing,
        guesses_data: @guesses.map(&:to_h)
      )
      self
    end

    def complete_round(player:)
      check_complete_round(player)

      guesser.score += guesses.score
      @document = document.with(status: Status.completed)
      self
    end

    def start_new_round(question:, guesser:)
      check_start_new_round(guesser)

      @guesses = Guesses.empty
      @document = document.with(
        question:,
        status: Status.polling,
        guesses_data: @guesses.map(&:to_h)
      )
      players.each do |player|
        player.reset_answer
        player.guesser = (player.id == guesser.id)
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
