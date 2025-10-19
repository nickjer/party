# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class Game
    class GuessesTest < ActiveSupport::TestCase
      test "#correct? returns true with case-insensitive match" do
        # Create game with custom answers for case-insensitive test
        game = create(:lq_matching_game,
          players: [
            { name: "Bob", answer: "Red" },
            { name: "Charlie", answer: "red" }
          ])

        # Get guesses
        guess1, guess2 = game.guesses.to_a

        # If guesses are not mismatched, swap them to ensure mismatch
        if guess1.player.id == guess1.guessed_player.id
          game.swap_guesses(player_id1: guess1.player.id,
            player_id2: guess2.player.id)
          game = LoadedQuestions::Game.from_slug(game.slug)
          guess1, guess2 = game.guesses.to_a
        end

        # Assert player IDs don't match guessed player IDs
        assert_not_equal guess1.player.id, guess1.guessed_player.id,
          "First guess should have different player and guessed_player IDs"
        assert_not_equal guess2.player.id, guess2.guessed_player.id,
          "Second guess should have different player and guessed_player IDs"

        # Assert both are correct due to case-insensitive matching
        assert_predicate guess1, :correct?,
          "First guess should be correct due to case-insensitive match"
        assert_predicate guess2, :correct?,
          "Second guess should be correct due to case-insensitive match"

        # Verify score is 2 (both correct)
        assert_equal 2, game.guesses.score
      end
    end
  end
end
