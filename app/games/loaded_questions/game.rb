# frozen_string_literal: true

module LoadedQuestions
  # Wrapper around ::Game model that provides Loaded Questions-specific
  # behavior and document parsing.
  class Game
    MIN_QUESTION_LENGTH = 3
    MAX_QUESTION_LENGTH = 160

    class << self
      def find(id) = new(scope.find(id))

      private

      def scope
        ::Game.strict_loading.loaded_questions.includes(players: :user)
      end
    end

    def initialize(game)
      @game = game
    end

    def id = game.id

    def guesses
      Guesses.parse(document.fetch(:guesses), players:)
    end

    def guesser
      players.find(&:guesser?) || raise("Couldn't find guesser")
    end

    def find_player(id)
      players.find { |player| player.id == id } || raise("Player not found")
    end

    def player_for!(user)
      player_for(user) ||
        raise(ActiveRecord::RecordNotFound, "Couldn't find Player")
    end

    def player_for(user) = players.find { |player| player.user == user }

    def players
      game.players.map { |player| Player.new(player) }.sort
    end

    def question = NormalizedString.new(document.fetch(:question))

    def status = Status.parse(document.fetch(:status))

    def to_model = game

    def swap_guesses(player_id1:, player_id2:)
      swapped_guesses = guesses.swap(player_id1:, player_id2:)
      document[:guesses] = swapped_guesses.as_json
      game.document = document.to_json
      game.save!
    end

    def update_status(new_status)
      if status.polling? && new_status.guessing?
        participants = players.select(&:answered?)
        shuffled_participants = participants.shuffle
        # @type var guess_pairs: Array[json_guessed_answer]
        guess_pairs =
          participants.zip(shuffled_participants)
            .map do |participant, guessed_participant|
              raise "Guessed participant is missing" unless guessed_participant

              { player_id: participant.id,
                guessed_player_id: guessed_participant.id }
            end
        document[:guesses] = guess_pairs
      elsif status.guessing? && new_status.completed?
        round_score = guesses.score
        current_guesser = guesser
        new_total_score = current_guesser.score + round_score
        current_guesser.score = new_total_score
        current_guesser.save!
      end

      document[:status] = new_status.to_s
      game.document = document.to_json
      game.save!
    end

    private

    # @dynamic game
    attr_reader :game

    def document = game.parsed_document #: json_document
  end
end
