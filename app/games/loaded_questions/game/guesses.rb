# frozen_string_literal: true

module LoadedQuestions
  class Game
    # Collection of guessed answers with operations for swapping and scoring.
    class Guesses
      class << self
        def parse(guesses, players:)
          player_map = players.index_by(&:id) #: Hash[String, Player]
          guesses = guesses
            .map do |guessed_answer|
              GuessedAnswer.new(
                player: player_map.fetch(guessed_answer[:player_id]),
                guessed_player: player_map.fetch(
                  guessed_answer[:guessed_player_id]
                )
              )
            end
          new(guesses:)
        end
      end

      include Enumerable

      def initialize(guesses:)
        @guesses = guesses
        validate_unique_players!
        validate_unique_guessed_players!
      end

      def each(&)
        guesses.each(&)
        self
      end

      def find(player_id)
        found_guess = guesses.find { |guess| guess.player.id == player_id }
        if found_guess.nil?
          raise ActiveRecord::RecordNotFound, "Couldn't find guessed answer"
        end

        found_guess
      end

      def size = guesses.size

      def swap(player_id1:, player_id2:)
        index1 = guesses.find_index { |guess| guess.player.id == player_id1 }
        index2 = guesses.find_index { |guess| guess.player.id == player_id2 }

        if index1.nil?
          raise ActiveRecord::RecordNotFound,
            "Player #{player_id1} not found"
        end
        if index2.nil?
          raise ActiveRecord::RecordNotFound,
            "Player #{player_id2} not found"
        end

        guess1 = guesses.fetch(index1)
        guess2 = guesses.fetch(index2)

        guesses[index1] = GuessedAnswer.new(player: guess1.player,
          guessed_player: guess2.guessed_player)
        guesses[index2] = GuessedAnswer.new(player: guess2.player,
          guessed_player: guess1.guessed_player)

        self
      end

      def as_json = guesses.map(&:as_json)

      def score = guesses.count(&:correct?)

      private

      # @dynamic guesses
      attr_reader :guesses

      def validate_unique_players!
        players = guesses.map(&:player)
        return if players.uniq.size == players.size

        raise "Duplicate player found in guesses"
      end

      def validate_unique_guessed_players!
        guessed_players = guesses.map(&:guessed_player)
        return if guessed_players.uniq.size == guessed_players.size

        raise "Duplicate guessed player found in guesses"
      end
    end
  end
end
