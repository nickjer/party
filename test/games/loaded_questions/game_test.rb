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

    test "#update_status updates guesser score when transitioning to " \
      "completed" do
      # Create a game in guessing status with players
      game = create(:lq_matching_game, player_names: %w[Bob Charlie])
      guesser = game.guesser

      assert_equal 0, guesser.score

      # Manually set guesses so they are all correct
      non_guessers = game.players.reject(&:guesser?)
      correct_guesses =
        non_guessers.map do |player|
          { player_id: player.id, guessed_player_id: player.id }
        end

      game_model = game.to_model
      document = game_model.parsed_document
      document[:guesses] = correct_guesses
      game_model.document = document.to_json
      game_model.save!

      # Reload game and verify score is 2 (both guesses correct)
      game = reload(game:)
      assert_equal 2, game.guesses.score

      # Transition to completed status
      game.update_status(Game::Status.completed)

      # Reload and verify guesser's score was incremented by 2
      game_after = reload(game:)
      guesser_after = game_after.guesser

      assert_equal 2, guesser_after.score,
        "Guesser score should be 2 when all guesses are correct"
    end
  end
end
