# frozen_string_literal: true

module LoadedQuestions
  # Aggregate for a Loaded Questions game. Persistence goes through GameRepo.
  # Identity methods delegate to ::Game for Rails interop (dom_id, GlobalID).
  class Game
    QUESTION_LENGTH = LengthValidator.new(min: 3, max: 160, field: :question)

    class << self
      def build(question:, id: nil)
        id ||= GameRepo.generate_id
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
      @document = document
      @players = players
      @guesses = Guesses.parse(document.guesses_data, players:)
    end

    def find_player(id)
      players.find { |player| player.id == id } || raise("Player not found")
    end

    def guesser
      players.find(&:guesser?) || raise("Couldn't find guesser")
    end

    # @dynamic guesses
    attr_reader :guesses

    def guesses=(new_guesses)
      @guesses = new_guesses
      @document = document.with(guesses_data: new_guesses.map(&:to_h))
    end

    def player_for!(user_id)
      player_for(user_id) ||
        raise(ActiveRecord::RecordNotFound, "Couldn't find Player")
    end

    def player_for(user_id)
      players.find { |player| player.user_id == user_id }
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

    def add_player(user_id:, name:, guesser: false)
      raise "Player already exists for user" if player_for(user_id)

      player = Player.build(game_id: id, user_id:, name:, guesser:)
      @players << player
      player
    end

    def assign_guess(player_id:, answer_id:)
      self.guesses = guesses.assign(player_id:, answer_id:)
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
