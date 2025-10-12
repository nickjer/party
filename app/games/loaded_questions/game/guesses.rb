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
                answer: guessed_answer[:answer]
              )
            end
          new(guesses:)
        end
      end

      include Enumerable

      def initialize(guesses:) = @guesses = guesses

      def each(&block)
        guesses.each(&block)
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

      def swap(player_id_1:, player_id_2:)
        index1 = guesses.find_index { |guess| guess.player.id == player_id_1 }
        index2 = guesses.find_index { |guess| guess.player.id == player_id_2 }

        raise ActiveRecord::RecordNotFound, "Player #{player_id_1} not found" if index1.nil?
        raise ActiveRecord::RecordNotFound, "Player #{player_id_2} not found" if index2.nil?

        answer1 = guesses.fetch(index1).answer
        answer2 = guesses.fetch(index2).answer

        guesses[index1] = GuessedAnswer.new(
          player: guesses.fetch(index1).player,
          answer: answer2
        )
        guesses[index2] = GuessedAnswer.new(
          player: guesses.fetch(index2).player,
          answer: answer1
        )

        self
      end

      def as_json
        guesses.map(&:as_json)
      end

      private

      class GuessedAnswer
        # @dynamic player
        attr_reader :player

        # @dynamic answer
        attr_reader :answer

        def initialize(player:, answer:)
          @player = player
          @answer = answer
        end

        def as_json
          { player_id: player.id, answer: }
        end
      end

      # @dynamic guesses
      attr_reader :guesses
    end
  end
end
