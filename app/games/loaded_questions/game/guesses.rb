# frozen_string_literal: true

module LoadedQuestions
  class Game
    # Collection of guessed answers with operations for assigning and scoring.
    class Guesses
      # Value object returned by Guesses#for_completed_view, pairing each player
      # with their actual answer and the player the guesser attributed it to.
      class CompletedGuess
        # @dynamic player, answer, attributed_to
        attr_reader :player, :answer, :attributed_to

        def initialize(player:, answer:, attributed_to:, correct:)
          @player = player
          @answer = answer
          @attributed_to = attributed_to
          @correct = correct
        end

        def correct? = @correct
      end

      class << self
        def empty = new(guesses: [])

        def parse(guesses, players:)
          player_map = players.index_by(&:id) #: Hash[String, Player]
          guesses = guesses
            .map do |guess_data|
              guessed_player_id = guess_data[:guessed_player_id]
              guessed_player =
                guessed_player_id ? player_map.fetch(guessed_player_id) : nil
              GuessedAnswer.new(
                player: player_map.fetch(guess_data[:player_id]),
                guessed_player:
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
          raise "Couldn't find guessed answer for player #{player_id}"
        end

        found_guess
      end

      def size = guesses.size

      def assigned = guesses.select(&:assigned?)

      def unassigned_answers
        assigned_answer_ids =
          guesses.filter_map { |guess| guess.guessed_answer&.id }
        answer_to_player_map
          .except(*assigned_answer_ids)
          .values
          .map(&:answer)
          .sort
      end

      def complete? = guesses.all?(&:assigned?)

      def for_completed_view
        inverse = {} #: Hash[String, Player]
        guesses.each do |guess|
          guessed_player = guess.guessed_player
          next unless guessed_player

          inverse[guessed_player.id] = guess.player
        end

        guesses.map do |guess|
          CompletedGuess.new(
            player: guess.player,
            answer: guess.answer,
            attributed_to: inverse.fetch(guess.player.id),
            correct: guess.correct?
          )
        end
      end

      def assign(player_id:, answer_id:)
        guessed_player = answer_id ? answer_to_player_map.fetch(answer_id) : nil

        new_guesses = guesses.map do |guess|
          if guess.player.id == player_id
            GuessedAnswer.new(player: guess.player, guessed_player:)
          elsif guessed_player && guess.guessed_player&.id == guessed_player.id
            GuessedAnswer.new(player: guess.player, guessed_player: nil)
          else
            guess
          end
        end

        Guesses.new(guesses: new_guesses)
      end

      def as_json = guesses.map(&:as_json)

      def score = guesses.count(&:correct?)

      private

      # @dynamic guesses
      attr_reader :guesses

      def answer_to_player_map
        @answer_to_player_map ||=
          guesses.to_h { |guess| [guess.player.answer.id, guess.player] }
      end

      def validate_unique_players!
        players = guesses.map(&:player)
        return if players.uniq.size == players.size

        raise "Duplicate player found in guesses"
      end

      def validate_unique_guessed_players!
        guessed_player_ids =
          guesses.filter_map { |guess| guess.guessed_player&.id }
        return if guessed_player_ids.uniq.size == guessed_player_ids.size

        raise "Duplicate guessed player found in guesses"
      end
    end
  end
end
