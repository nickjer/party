# frozen_string_literal: true

module LoadedQuestions
  class Game
    # Value object representing a player's answer matched with the
    # guesser's guess.
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
  end
end
