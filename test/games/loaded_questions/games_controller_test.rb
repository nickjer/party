# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class GamesControllerTest < ActionDispatch::IntegrationTest
    test "#swap_guesses persists answer swap to database" do
      # Create game in guessing status with players and answers
      game = create(:lq_matching_game, player_names: %w[Bob Charlie])

      # Get current answer assignments
      guess1, guess2 = game.guesses.to_a
      guess1_guessed_answer_before = guess1.guessed_answer
      guess2_guessed_answer_before = guess2.guessed_answer

      # Swap the answers
      game.swap_guesses(player_id1: guess1.player.id,
        player_id2: guess2.player.id)

      # Reload from database to verify persistence
      game_after = Game.from_slug(game.slug)
      guess1_after, guess2_after = game_after.guesses.to_a

      # Verify answers were swapped and persisted
      assert_equal guess2_guessed_answer_before, guess1_after.guessed_answer,
        "First guess should have second guessed answer after swap"
      assert_equal guess1_guessed_answer_before, guess2_after.guessed_answer,
        "Second guess should have first guessed answer after swap"
    end

    test "#completed_round changes game status from guessing to completed" do
      # Create game in guessing status with players and answers
      game = create(:lq_matching_game, player_names: %w[Bob Charlie])

      # Verify game is in guessing status
      assert_predicate game.status, :guessing?

      # Sign in as guesser
      guesser = game.players.find(&:guesser?)
      sign_in(guesser.user)

      # Make request to complete round
      patch completed_round_loaded_questions_game_path(game.slug)

      # Verify successful response
      assert_response :success

      # Reload and verify game status changed to completed
      game = LoadedQuestions::Game.from_slug(game.slug)
      assert_predicate game.status, :completed?
    end

    test "#completed_round returns error when not in guessing phase" do
      # Create game with guesser and players in polling phase
      game = create(:lq_game, player_names: %w[Bob Charlie])

      # Verify game is in polling status
      assert_predicate game.status, :polling?

      # Sign in as guesser
      guesser = game.players.find(&:guesser?)
      sign_in(guesser.user)

      # Try to complete round while still in polling phase
      patch completed_round_loaded_questions_game_path(game.slug)

      # Verify unprocessable_content response
      assert_response :unprocessable_content

      # Reload and verify game status has not changed
      game = LoadedQuestions::Game.from_slug(game.slug)
      assert_predicate game.status, :polling?
    end

    test "#new_round returns forbidden when guesser tries to access" do
      # Create completed game
      game = create(:lq_completed_game)

      # Sign in as guesser
      guesser = game.players.find(&:guesser?)
      sign_in(guesser.user)

      # Try to access new_round as guesser
      get new_round_loaded_questions_game_path(game.slug)

      # Verify forbidden response
      assert_response :forbidden
    end

    test "#create_round returns forbidden when guesser tries to create" do
      # Create completed game
      game = create(:lq_completed_game)

      # Sign in as guesser
      guesser = game.players.find(&:guesser?)
      sign_in(guesser.user)

      # Try to create new round as guesser
      post create_round_loaded_questions_game_path(game.slug), params: {
        round: {
          question: "New question?"
        }
      }

      # Verify forbidden response
      assert_response :forbidden
    end

    test "#completed_round returns forbidden when non-guesser tries" do
      # Create game in guessing status
      game = create(:lq_matching_game)

      # Sign in as non-guesser
      non_guesser = game.players.find { |p| !p.guesser? }
      sign_in(non_guesser.user)

      # Try to complete round as non-guesser
      patch completed_round_loaded_questions_game_path(game.slug)

      # Verify forbidden response
      assert_response :forbidden
    end

    test "#guessing_round returns forbidden when non-guesser tries" do
      # Create game with players and answers in polling status
      game = create(:lq_game, :with_players, :with_answers)

      # Verify game is in polling status
      assert_predicate game.status, :polling?

      # Sign in as non-guesser
      non_guesser = game.players.find { |p| !p.guesser? }
      sign_in(non_guesser.user)

      # Try to start guessing round as non-guesser
      patch guessing_round_loaded_questions_game_path(game.slug)

      # Verify forbidden response
      assert_response :forbidden
    end

    test "#swap_guesses returns forbidden when non-guesser tries" do
      # Create game in guessing status
      game = create(:lq_matching_game)

      # Sign in as non-guesser
      non_guesser = game.players.find { |p| !p.guesser? }
      sign_in(non_guesser.user)

      # Try to swap guesses as non-guesser
      guess1, guess2 = game.guesses.to_a
      patch swap_guesses_loaded_questions_game_path(game.slug), params: {
        guess_swapper: {
          guess_id: guess1.player.id,
          swap_guess_id: guess2.player.id
        }
      }

      # Verify forbidden response
      assert_response :forbidden
    end

    test "#swap_guesses returns forbidden when not in guessing phase" do
      # Create game with players and answers in polling status
      game = create(:lq_game, :with_players, :with_answers)

      # Verify game is in polling status
      assert_predicate game.status, :polling?

      # Sign in as guesser
      guesser = game.players.find(&:guesser?)
      sign_in(guesser.user)

      # Try to swap guesses while still in polling phase
      non_guessers = game.players.reject(&:guesser?)
      patch swap_guesses_loaded_questions_game_path(game.slug), params: {
        guess_swapper: {
          guess_id: non_guessers[0].id,
          swap_guess_id: non_guessers[1].id
        }
      }

      # Verify forbidden response
      assert_response :forbidden
    end
  end
end
