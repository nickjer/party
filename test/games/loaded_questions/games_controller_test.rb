# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class GamesControllerTest < ActionDispatch::IntegrationTest
    test "#new renders new game form" do
      user = create(:user)
      sign_in(user.id)

      get new_loaded_questions_game_path

      assert_response :success
      assert_dom "input[name='game[player_name]']"
      assert_dom "textarea[name='game[question]']"
    end

    test "#show redirects to new player when user not in game" do
      game = create(:lq_game)
      user = create(:user)
      sign_in(user.id)

      get loaded_questions_game_path(game.id)

      assert_response :redirect
      assert_redirected_to new_loaded_questions_game_player_path(game.id)
    end

    test "#show renders polling_guesser when polling and guesser" do
      game = create(:lq_polling_game)
      guesser = game.players.find(&:guesser?)
      sign_in(guesser.user_id)

      assert_predicate game.status, :polling?
      assert_predicate guesser, :guesser?

      get loaded_questions_game_path(game.id)

      assert_response :success
      assert_dom "button", text: "Begin Guessing"
      assert_not_dom "textarea[name='player[answer]']"
      assert_not_dom "button", text: "Complete Matching"
    end

    test "#show renders polling_player when polling and not guesser" do
      game = create(:lq_polling_game, player_names: %w[Bob])
      non_guesser = game.players.reject(&:guesser?).first
      sign_in(non_guesser.user_id)

      assert_predicate game.status, :polling?
      assert_not_predicate non_guesser, :guesser?

      get loaded_questions_game_path(game.id)

      assert_response :success
      assert_dom "textarea[name='player[answer]']"
      assert_not_dom "button", text: "Begin Guessing"
      assert_not_dom "button", text: "Complete Matching"
    end

    test "#show renders guessing_guesser when guessing and guesser" do
      game = create(:lq_matching_game)
      guesser = game.players.find(&:guesser?)
      sign_in(guesser.user_id)

      assert_predicate game.status, :guessing?
      assert_predicate guesser, :guesser?

      get loaded_questions_game_path(game.id)

      assert_response :success
      assert_dom "button", text: "Complete Matching"
      assert_not_dom "textarea[name='player[answer]']"
      assert_not_dom "button", text: "Begin Guessing"
    end

    test "#show renders guessing_player when guessing and not guesser" do
      game = create(:lq_matching_game)
      non_guesser = game.players.reject(&:guesser?).first
      sign_in(non_guesser.user_id)

      assert_predicate game.status, :guessing?
      assert_not_predicate non_guesser, :guesser?

      get loaded_questions_game_path(game.id)

      assert_response :success
      assert_not_dom "textarea[name='player[answer]']"
      assert_not_dom "button", text: "Begin Guessing"
      assert_not_dom "button", text: "Complete Matching"
    end

    test "#show renders completed when game completed" do
      game = create(:lq_completed_game)
      player = game.players.first
      sign_in(player.user_id)

      assert_predicate game.status, :completed?

      get loaded_questions_game_path(game.id)

      assert_response :success
      assert_match(/Score:/, response.body)
      assert_not_dom "textarea[name='player[answer]']"
      assert_not_dom "button", text: "Begin Guessing"
      assert_not_dom "button", text: "Complete Matching"
    end

    test "#completed_round changes game status from guessing to completed" do
      # Create game in guessing status with players and answers
      game = create(:lq_matching_game, player_names: %w[Bob Charlie])

      # Assign all guesses (required for completion)
      game.guesses.each do |guess|
        game.assign_guess(player_id: guess.player.id,
          answer_id: guess.player.answer.id)
      end
      game.save!

      # Verify game is in guessing status
      assert_predicate game.status, :guessing?

      # Sign in as guesser
      guesser = game.players.find(&:guesser?)
      sign_in(guesser.user_id)

      # Make request to complete round
      patch completed_round_loaded_questions_game_path(game.id)

      # Verify successful response
      assert_response :success

      # Reload and verify game status changed to completed
      game = reload(game:)
      assert_predicate game.status, :completed?
    end

    test "#completed_round returns error when not in guessing phase" do
      # Create game with guesser and players in polling phase
      game = create(:lq_polling_game, player_names: %w[Bob Charlie])

      # Verify game is in polling status
      assert_predicate game.status, :polling?

      # Sign in as guesser
      guesser = game.players.find(&:guesser?)
      sign_in(guesser.user_id)

      # Try to complete round while still in polling phase
      patch completed_round_loaded_questions_game_path(game.id)

      # Verify unprocessable_content response
      assert_response :unprocessable_content

      # Reload and verify game status has not changed
      game = reload(game:)
      assert_predicate game.status, :polling?
    end

    test "#completed_round returns forbidden when non-guesser tries" do
      # Create game in guessing status
      game = create(:lq_matching_game)

      # Sign in as non-guesser
      non_guesser = game.players.find { |p| !p.guesser? }
      sign_in(non_guesser.user_id)

      # Try to complete round as non-guesser
      patch completed_round_loaded_questions_game_path(game.id)

      # Verify forbidden response
      assert_response :forbidden
    end

    test "#create creates game and player in database" do
      user = create(:user)
      sign_in(user.id)

      assert_difference ["::Game.count", "::Player.count"], 1 do
        post loaded_questions_games_path, params: {
          game: {
            player_name: "Alice",
            question: "What is your favorite color?"
          }
        }
      end

      assert_response :redirect
    end

    test "#create redirects to game show page with valid params" do
      user = create(:user)
      sign_in(user.id)

      post loaded_questions_games_path, params: {
        game: {
          player_name: "Alice",
          question: "What is your favorite color?"
        }
      }

      assert_response :redirect
      follow_redirect!
      assert_response :success
    end

    test "#create renders form with validation errors" do
      user = create(:user)
      sign_in(user.id)

      post loaded_questions_games_path, params: {
        game: {
          player_name: "ab",
          question: "What is your favorite color?"
        }
      }

      assert_response :unprocessable_content
      assert_dom "input[name='game[player_name]']"
      assert_match(/is too short/, response.body)
    end

    test "#create_round creates new round and changes guesser" do
      game = create(:lq_completed_game)
      non_guesser = game.players.reject(&:guesser?).first
      sign_in(non_guesser.user_id)

      post create_round_loaded_questions_game_path(game.id), params: {
        round: {
          question: "What is your favorite food?"
        }
      }

      assert_response :success
      game = reload(game:)
      assert_predicate game.status, :polling?
      assert_predicate game.player_for(non_guesser.user_id), :guesser?
    end

    test "#create_round renders form with validation errors" do
      game = create(:lq_completed_game)
      non_guesser = game.players.reject(&:guesser?).first
      sign_in(non_guesser.user_id)

      post create_round_loaded_questions_game_path(game.id), params: {
        round: {
          question: "ab"
        }
      }

      assert_response :unprocessable_content
      assert_match(/is too short/, response.body)
    end

    test "#create_round returns forbidden when guesser tries to create" do
      # Create completed game
      game = create(:lq_completed_game)

      # Sign in as guesser
      guesser = game.players.find(&:guesser?)
      sign_in(guesser.user_id)

      # Try to create new round as guesser
      post create_round_loaded_questions_game_path(game.id), params: {
        round: {
          question: "New question?"
        }
      }

      # Verify forbidden response
      assert_response :forbidden
    end

    test "#guessing_round returns forbidden when non-guesser tries" do
      # Create game with players and answers in polling status
      game = create(:lq_polling_game)

      # Verify game is in polling status
      assert_predicate game.status, :polling?

      # Sign in as non-guesser
      non_guesser = game.players.find { |p| !p.guesser? }
      sign_in(non_guesser.user_id)

      # Try to start guessing round as non-guesser
      patch guessing_round_loaded_questions_game_path(game.id)

      # Verify forbidden response
      assert_response :forbidden
    end

    test "#guessing_round transitions from polling to guessing" do
      game = create(:lq_polling_game, :with_answers)
      guesser = game.players.find(&:guesser?)
      sign_in(guesser.user_id)

      assert_predicate game.status, :polling?

      patch guessing_round_loaded_questions_game_path(game.id)

      assert_response :success
      game = reload(game:)
      assert_predicate game.status, :guessing?
    end

    test "#guessing_round renders form with validation errors when not " \
      "enough answers" do
      game = create(:lq_polling_game, player_names: %w[Bob Charlie])
      guesser = game.players.find(&:guesser?)
      sign_in(guesser.user_id)

      assert_predicate game.status, :polling?

      patch guessing_round_loaded_questions_game_path(game.id)

      assert_response :unprocessable_content
      assert_match(/Not enough players have answered/, response.body)
    end

    test "#new_round returns forbidden when guesser tries to access" do
      # Create completed game
      game = create(:lq_completed_game)

      # Sign in as guesser
      guesser = game.players.find(&:guesser?)
      sign_in(guesser.user_id)

      # Try to access new_round as guesser
      get new_round_loaded_questions_game_path(game.id)

      # Verify forbidden response
      assert_response :forbidden
    end

    test "#new_round renders form for non-guesser" do
      game = create(:lq_completed_game)
      non_guesser = game.players.reject(&:guesser?).first
      sign_in(non_guesser.user_id)

      get new_round_loaded_questions_game_path(game.id)

      assert_response :success
      assert_dom "textarea[name='round[question]']"
    end

    test "#assign_guess assigns answer and returns ok" do
      game = create(:lq_matching_game, player_names: %w[Bob Charlie])
      guesser = game.players.find(&:guesser?)
      sign_in(guesser.user_id)

      bob, charlie = game.guesses.map(&:player)

      patch assign_guess_loaded_questions_game_path(game.id), params: {
        guess_assignment: {
          player_id: charlie.id,
          answer_id: bob.answer.id
        }
      }

      assert_response :ok
      game = reload(game:)
      charlie_guess = game.guesses.find(charlie.id)

      assert_equal bob.answer, charlie_guess.guessed_answer
    end

    test "#assign_guess returns forbidden when non-guesser tries" do
      game = create(:lq_matching_game)
      non_guesser = game.players.find { |player| !player.guesser? }
      sign_in(non_guesser.user_id)

      bob = game.guesses.first.player

      patch assign_guess_loaded_questions_game_path(game.id), params: {
        guess_assignment: {
          player_id: bob.id,
          answer_id: bob.answer.id
        }
      }

      assert_response :forbidden
    end

    test "#assign_guess returns forbidden when not in guessing phase" do
      game = create(:lq_polling_game)

      assert_predicate game.status, :polling?

      guesser = game.players.find(&:guesser?)
      sign_in(guesser.user_id)

      non_guesser = game.players.reject(&:guesser?).first

      patch assign_guess_loaded_questions_game_path(game.id), params: {
        guess_assignment: {
          player_id: non_guesser.id,
          answer_id: "some-answer-id"
        }
      }

      assert_response :forbidden
    end
  end
end
