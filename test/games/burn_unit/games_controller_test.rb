# frozen_string_literal: true

require "test_helper"

module BurnUnit
  class GamesControllerTest < ActionDispatch::IntegrationTest
    test "#new renders new game form" do
      user = create(:user)
      sign_in(user.id)

      get new_burn_unit_game_path

      assert_response :success
      assert_dom "input[name='game[player_name]']"
      assert_dom "textarea[name='game[question]']"
    end

    test "#show redirects to new player when user not in game" do
      game = create(:bu_game)
      user = create(:user)
      sign_in(user.id)

      get burn_unit_game_path(game.id)

      assert_response :redirect
      assert_redirected_to new_burn_unit_game_player_path(game.id)
    end

    test "#show renders polling_judge when polling and judge" do
      game = create(:bu_polling_game)
      judge = game.players.find(&:judge?)
      sign_in(judge.user_id)

      assert_predicate game.status, :polling?
      assert_predicate judge, :judge?

      get burn_unit_game_path(game.id)

      assert_response :success
      assert_dom "button", text: "Tally Votes"
      assert_dom "select[aria-label='Vote for player']"
    end

    test "#show renders polling_player when polling and not judge" do
      game = create(:bu_polling_game, player_names: %w[Bob])
      non_judge = game.players.reject(&:judge?).first
      sign_in(non_judge.user_id)

      assert_predicate game.status, :polling?
      assert_not_predicate non_judge, :judge?

      get burn_unit_game_path(game.id)

      assert_response :success
      assert_dom "select[aria-label='Vote for player']"
      assert_not_dom "button", text: "Tally Votes"
    end

    test "#show renders completed when game completed" do
      game = create(:bu_completed_game)
      player = game.players.first
      sign_in(player.user_id)

      assert_predicate game.status, :completed?

      get burn_unit_game_path(game.id)

      assert_response :success
      assert_match(/Results/, response.body)
      assert_not_dom "button", text: "Tally Votes"
    end

    test "#show sets player as playing when visiting during polling" do
      game = create(:bu_polling_game)
      non_judge = game.players.reject(&:judge?).first
      non_judge.playing = false
      non_judge.save!
      sign_in(non_judge.user_id)

      assert_not_predicate non_judge, :playing?

      get burn_unit_game_path(game.id)

      assert_response :success
      game = reload(game:)
      updated_player = game.player_for(non_judge.user_id)
      assert_predicate updated_player, :playing?
    end

    test "#completed_round changes game status from polling to completed" do
      game = create(:bu_polling_game, players: [
        { name: "Bob", vote_for: "Charlie" },
        { name: "Charlie", vote_for: "Bob" }
      ])

      assert_predicate game.status, :polling?

      judge = game.players.find(&:judge?)
      sign_in(judge.user_id)

      patch completed_round_burn_unit_game_path(game.id)

      assert_response :success
      game = reload(game:)
      assert_predicate game.status, :completed?
    end

    test "#completed_round returns error when not enough votes" do
      game = create(:bu_polling_game, players: [
        { name: "Bob", vote_for: "Charlie" }
      ])

      assert_predicate game.status, :polling?

      judge = game.players.find(&:judge?)
      sign_in(judge.user_id)

      patch completed_round_burn_unit_game_path(game.id)

      assert_response :unprocessable_content
      assert_match(/Need at least 2 votes to tally/, response.body)

      game = reload(game:)
      assert_predicate game.status, :polling?
    end

    test "#completed_round returns forbidden when non-judge tries" do
      game = create(:bu_polling_game)
      non_judge = game.players.find { |p| !p.judge? }
      sign_in(non_judge.user_id)

      patch completed_round_burn_unit_game_path(game.id)

      assert_response :forbidden
    end

    test "#create creates game and player in database" do
      user = create(:user)
      sign_in(user.id)

      assert_difference ["::Game.count", "::Player.count"], 1 do
        post burn_unit_games_path, params: {
          game: {
            player_name: "Alice",
            question: "Who is most likely to win?"
          }
        }
      end

      assert_response :redirect
    end

    test "#create redirects to game show page with valid params" do
      user = create(:user)
      sign_in(user.id)

      post burn_unit_games_path, params: {
        game: {
          player_name: "Alice",
          question: "Who is most likely to win?"
        }
      }

      assert_response :redirect
      follow_redirect!
      assert_response :success
    end

    test "#create renders form with validation errors" do
      user = create(:user)
      sign_in(user.id)

      post burn_unit_games_path, params: {
        game: {
          player_name: "ab",
          question: "Who is most likely to win?"
        }
      }

      assert_response :unprocessable_content
      assert_dom "input[name='game[player_name]']"
      assert_match(/is too short/, response.body)
    end

    test "#create_round creates new round and changes judge" do
      game = create(:bu_completed_game)
      non_judge = game.players.reject(&:judge?).first
      sign_in(non_judge.user_id)

      post create_round_burn_unit_game_path(game.id), params: {
        round: {
          question: "Who would win in a fight?"
        }
      }

      assert_response :success
      game = reload(game:)
      assert_predicate game.status, :polling?
      assert_predicate game.player_for(non_judge.user_id), :judge?
    end

    test "#create_round renders form with validation errors" do
      game = create(:bu_completed_game)
      non_judge = game.players.reject(&:judge?).first
      sign_in(non_judge.user_id)

      post create_round_burn_unit_game_path(game.id), params: {
        round: {
          question: "ab"
        }
      }

      assert_response :unprocessable_content
      assert_match(/is too short/, response.body)
    end

    test "#create_round returns forbidden when judge tries to create" do
      game = create(:bu_completed_game)
      judge = game.players.find(&:judge?)
      sign_in(judge.user_id)

      post create_round_burn_unit_game_path(game.id), params: {
        round: {
          question: "New question?"
        }
      }

      assert_response :forbidden
    end

    test "#new_round returns forbidden when judge tries to access" do
      game = create(:bu_completed_game)
      judge = game.players.find(&:judge?)
      sign_in(judge.user_id)

      get new_round_burn_unit_game_path(game.id)

      assert_response :forbidden
    end

    test "#new_round renders form for non-judge" do
      game = create(:bu_completed_game)
      non_judge = game.players.reject(&:judge?).first
      sign_in(non_judge.user_id)

      get new_round_burn_unit_game_path(game.id)

      assert_response :success
      assert_dom "textarea[name='round[question]']"
    end
  end
end
