# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class Game
    class GuessedAnswerTest < ActiveSupport::TestCase
      test "#correct? returns true with case-insensitive match" do
        # Create game with custom answers for case-insensitive test
        game = build(:lq_matching_game,
          players: [
            { name: "Bob", answer: "Red" },
            { name: "Charlie", answer: "red" }
          ])

        # Get players
        bob, charlie = game.guesses.map(&:player)

        # Assign swapped guesses (Bob gets Charlie's "red", Charlie gets Bob's "Red")
        game.assign_guess(player_id: bob.id, answer_id: charlie.answer.id)
        game.assign_guess(player_id: charlie.id, answer_id: bob.answer.id)

        # Get updated guesses
        bob_guess = game.guesses.find(bob.id)
        charlie_guess = game.guesses.find(charlie.id)

        # Assert player IDs don't match guessed player IDs
        assert_not_equal bob.id, bob_guess.guessed_player.id
        assert_not_equal charlie.id, charlie_guess.guessed_player.id

        # Assert both are correct due to case-insensitive matching ("Red" == "red")
        assert_predicate bob_guess, :correct?
        assert_predicate charlie_guess, :correct?

        # Verify score is 2 (both correct)
        assert_equal 2, game.guesses.score
      end
    end
  end
end
