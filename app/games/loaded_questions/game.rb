# frozen_string_literal: true

module LoadedQuestions
  class Game
    class << self
      def find(slug)
        relation = ::Game.strict_loading.loaded_questions
          .includes(players: :user)
        new(relation.find_by!(slug:))
      end
    end

    def initialize(game)
      @game = game
    end

    def broadcast_reload_game = game.broadcast_reload_game

    def broadcast_reload_players = game.broadcast_reload_players

    def id = game.id

    def guesses
      Guesses.parse(document.fetch(:guesses), players:)
    end

    def guesser
      players.find(&:guesser?) || raise("Couldn't find guesser")
    end

    def player_for!(user)
      player_for(user) ||
        raise(ActiveRecord::RecordNotFound, "Couldn't find Player")
    end

    def player_for(user) = players.find { |player| player.user == user }

    def players
      game.players.map { |player| Player.new(player, game: self) }.sort
    end

    def question = document.fetch(:question)

    def slug = game.slug

    def status = Status.parse(document.fetch(:status))

    def swap_guesses(player_id_1:, player_id_2:)
      swapped_guesses = guesses.swap(player_id_1:, player_id_2:)
      document[:guesses] = swapped_guesses.as_json
      game.document = document.to_json
      game.save!
    end

    def update_status(new_status)
      if status.polling? && new_status.guessing?
        participants = players.select(&:answered?)
        shuffled_participants = participants.shuffle
        # @type var guesses: Array[guessed_answer]
        guesses =
          participants.zip(shuffled_participants).map do |participant, guessed_participant|
            raise "Guessed participant is missing" unless guessed_participant

            { player_id: participant.id,
              guessed_player_id: guessed_participant.id }
          end
        document[:guesses] = guesses
      end

      document[:status] = new_status.to_s
      game.document = document.to_json
      game.save!
    end

    private

    # @dynamic game
    attr_reader :game

    def document = game.parsed_document #: document
  end
end
