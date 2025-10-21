# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class PlayersControllerTest < ActionDispatch::IntegrationTest
    test "#answer updates player answer and returns ok" do
      game = create(:lq_game)
      bob = create(:lq_player, game:)
      sign_in(bob.user_id)

      assert_predicate bob.answer, :blank?

      patch answer_loaded_questions_game_player_path(game.id), params: {
        player: {
          answer: "My answer"
        }
      }

      assert_response :ok
      game = reload(game:)
      bob = game.player_for(bob.user_id)
      assert_equal "My answer", bob.answer.to_s
    end

    test "#answer returns validation error for single letter answer" do
      game = create(:lq_game)
      bob = create(:lq_player, game:)
      sign_in(bob.user_id)

      patch answer_loaded_questions_game_player_path(game.id), params: {
        player: {
          answer: "A"
        }
      }

      assert_response :unprocessable_content
      assert_dom "textarea[name='player[answer]']"
      assert_match(/is too short/, response.body)
    end

    test "#answer redirects to new player when current player is nil" do
      game = create(:lq_game)
      user = create(:user)
      sign_in(user.id)

      patch answer_loaded_questions_game_player_path(game.id), params: {
        player: {
          answer: "My answer"
        }
      }

      assert_redirected_to new_loaded_questions_game_player_path(game.id)
    end

    test "#create creates player and redirects to game" do
      game = create(:lq_game)
      user = create(:user)
      sign_in(user.id)

      assert_difference "::Player.count", 1 do
        post loaded_questions_game_player_path(game.id), params: {
          player: {
            name: "Charlie"
          }
        }
      end

      assert_response :redirect
      assert_redirected_to loaded_questions_game_path(game.id)
    end

    test "#create renders form with validation errors" do
      game = create(:lq_game)
      user = create(:user)
      sign_in(user.id)

      post loaded_questions_game_player_path(game.id), params: {
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
      sign_in(user.id)

      get new_loaded_questions_game_player_path(game.id)

      assert_response :success
      assert_dom "input[name='player[name]']"
    end

    test "#new redirects to game when user already in game" do
      game = create(:lq_game)
      guesser = game.players.find(&:guesser?)
      sign_in(guesser.user_id)

      get new_loaded_questions_game_player_path(game.id)

      assert_response :redirect
      assert_redirected_to loaded_questions_game_path(game.id)
    end

    test "#edit renders edit player form for current player" do
      game = create(:lq_game)
      guesser = game.players.find(&:guesser?)
      sign_in(guesser.user_id)

      get edit_loaded_questions_game_player_path(game.id)

      assert_response :success
      assert_dom "input[name='player[name]']"
      assert_dom "input[type='submit'][value='Update Name']"
    end

    test "#edit populates form with current player name" do
      game = create(:lq_game, player_names: %w[Alice Bob])
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      sign_in(alice.user_id)

      get edit_loaded_questions_game_player_path(game.id)

      assert_response :success
      assert_dom "input[name='player[name]'][value='Alice']"
    end

    test "#edit redirects to new player when current player is nil" do
      game = create(:lq_game)
      user = create(:user)
      sign_in(user.id)

      get edit_loaded_questions_game_player_path(game.id)

      assert_redirected_to new_loaded_questions_game_player_path(game.id)
    end

    test "#update updates player name and redirects to game" do
      game = create(:lq_game, player_names: %w[Alice Bob])
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      sign_in(alice.user_id)

      patch loaded_questions_game_player_path(game.id), params: {
        player: {
          name: "Alicia"
        }
      }

      assert_redirected_to loaded_questions_game_path(game.id)
      game = reload(game:)
      updated_player = game.player_for(alice.user_id)
      assert_equal "Alicia", updated_player.name.to_s
    end

    test "#update returns validation error for short name" do
      game = create(:lq_game, player_names: %w[Alice Bob])
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      sign_in(alice.user_id)

      patch loaded_questions_game_player_path(game.id), params: {
        player: {
          name: "Al"
        }
      }

      assert_response :unprocessable_content
      assert_dom "input[name='player[name]']"
      assert_match(/is too short/, response.body)
    end

    test "#update returns validation error for duplicate name" do
      game = create(:lq_game, player_names: %w[Alice Bob])
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      sign_in(alice.user_id)

      patch loaded_questions_game_player_path(game.id), params: {
        player: {
          name: "bob"
        }
      }

      assert_response :unprocessable_content
      assert_dom "input[name='player[name]']"
      assert_match(/has already been taken/, response.body)
    end

    test "#update redirects to new player when current player is nil" do
      game = create(:lq_game)
      user = create(:user)
      sign_in(user.id)

      patch loaded_questions_game_player_path(game.id), params: {
        player: {
          name: "Charlie"
        }
      }

      assert_redirected_to new_loaded_questions_game_player_path(game.id)
    end
  end
end
