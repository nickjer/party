# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class GameTest < ActiveSupport::TestCase
    test "swap_guesses persists answer swap to database" do
      # Create game in guessing status with players and answers
      game = create(:lq_matching_game, player_names: %w[Bob Charlie])

      # Get current answer assignments
      guess1, guess2 = game.guesses.to_a
      guess1_guessed_answer_before = guess1.guessed_answer
      guess2_guessed_answer_before = guess2.guessed_answer

      # Swap the answers
      game.swap_guesses(player_id1: guess1.player.id,
        player_id2: guess2.player.id)
      game.save!

      # Reload from database to verify persistence
      game_after = reload(game:)
      guess1_after, guess2_after = game_after.guesses.to_a

      # Verify answers were swapped and persisted
      assert_equal guess2_guessed_answer_before, guess1_after.guessed_answer,
        "First guess should have second guessed answer after swap"
      assert_equal guess1_guessed_answer_before, guess2_after.guessed_answer,
        "Second guess should have first guessed answer after swap"
    end
  end
end
