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
      end

      # @dynamic guesses
      attr_reader :guesses
    end
  end
end
