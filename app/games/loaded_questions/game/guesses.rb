# frozen_string_literal: true

module LoadedQuestions
  class Game
    class Guesses
      class << self
        def parse(guesses, players:)
          player_map = players.index_by(&:id) #: Hash[Integer, Player]
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

      def initialize(guesses:) = @guesses = guesses

      def each(&)
        guesses.each(&)
        self
      end

      def find(player_id)
        found_guess = guesses.find { |guess| guess.player.id == player_id }
        raise ActiveRecord::RecordNotFound, "Couldn't find guessed answer" if found_guess.nil?

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

      class GuessedAnswer
        # @dynamic player, guessed_player
        attr_reader :player, :guessed_player

        def initialize(player:, guessed_player:)
          @player = player
          @guessed_player = guessed_player
        end

        def answer = player.answer

        def guessed_answer = guessed_player.answer

        def correct? = answer == guessed_answer

        def as_json
          { player_id: player.id,
            guessed_player_id: guessed_player.id }
        end
      end

      # @dynamic guesses
      attr_reader :guesses
    end
  end
end
