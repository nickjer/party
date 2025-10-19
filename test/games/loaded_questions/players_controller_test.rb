# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class PlayersControllerTest < ActionDispatch::IntegrationTest
    test "#answer updates player answer and returns ok" do
      game = create(:lq_game)
      bob = create(:lq_player, game:)
      sign_in(bob.user)

      assert_predicate bob.answer, :blank?

      patch answer_loaded_questions_game_player_path(game.slug), params: {
        player: {
          answer: "My answer"
        }
      }

      assert_response :ok
      game = reload(game:)
      bob = game.player_for(bob.user)
      assert_equal "My answer", bob.answer.to_s
    end

    test "#answer returns validation error for single letter answer" do
      game = create(:lq_game)
      bob = create(:lq_player, game:)
      sign_in(bob.user)

      patch answer_loaded_questions_game_player_path(game.slug), params: {
        player: {
          answer: "A"
        }
      }

      assert_response :unprocessable_content
      assert_dom "textarea[name='player[answer]']"
      assert_match(/is too short/, response.body)
    end

    test "#create creates player and redirects to game" do
      game = create(:lq_game)
      user = create(:user)
      sign_in(user)

      assert_difference "::Player.count", 1 do
        post loaded_questions_game_player_path(game.slug), params: {
          player: {
            name: "Charlie"
          }
        }
      end

      assert_response :redirect
      assert_redirected_to loaded_questions_game_path(game.slug)
    end

    test "#create renders form with validation errors" do
      game = create(:lq_game)
      user = create(:user)
      sign_in(user)

      post loaded_questions_game_player_path(game.slug), params: {
        player: {
          name: "ab"
        }
      }

      assert_response :unprocessable_content
      assert_dom "input[name='player[name]']"
      assert_match(/is too short/, response.body)
    end

    test "#new renders new player form when user not in game" do
      game = create(:lq_game)
      user = create(:user)
      sign_in(user)

      get new_loaded_questions_game_player_path(game.slug)

      assert_response :success
      assert_dom "input[name='player[name]']"
    end

    test "#new redirects to game when user already in game" do
      game = create(:lq_game)
      guesser = game.players.find(&:guesser?)
      sign_in(guesser.user)

      get new_loaded_questions_game_player_path(game.slug)

      assert_response :redirect
      assert_redirected_to loaded_questions_game_path(game.slug)
    end
  end
end
