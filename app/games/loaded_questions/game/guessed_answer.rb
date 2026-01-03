# frozen_string_literal: true

module LoadedQuestions
  class Game
    # Value object representing a player paired with the player the guesser
    # thinks wrote their answer. The guessed_player can be nil when no guess
    # has been assigned yet.
    class GuessedAnswer
      # @dynamic player, guessed_player
      attr_reader :player, :guessed_player

      def initialize(player:, guessed_player:)
        @player = player
        @guessed_player = guessed_player
      end

      def answer = player.answer

      def guessed_answer = guessed_player&.answer

      def assigned? = !guessed_player.nil?

      def correct? = assigned? && guessed_answer == answer

      def as_json
        { player_id: player.id, guessed_player_id: guessed_player&.id }.as_json
      end
    end
  end
end
