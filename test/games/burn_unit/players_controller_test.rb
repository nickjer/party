# frozen_string_literal: true

require "test_helper"

module BurnUnit
  class PlayersControllerTest < ActionDispatch::IntegrationTest
    test "#vote updates player vote and returns ok" do
      game = create(:bu_polling_game, player_names: %w[Bob])
      bob = game.players.find { |p| p.name.to_s == "Bob" }
      alice = game.players.find { |p| p.name.to_s != "Bob" }
      sign_in(bob.user_id)

      assert_not_predicate bob, :voted?

      patch vote_burn_unit_game_player_path(game.id), params: {
        player: {
          candidate_id: alice.id
        }
      }

      assert_response :ok
      game = reload(game:)
      bob = game.player_for(bob.user_id)
      assert_equal alice.id, bob.vote
    end

    test "#vote returns validation error for missing candidate" do
      game = create(:bu_polling_game, player_names: %w[Bob])
      bob = game.players.find { |p| p.name.to_s == "Bob" }
      sign_in(bob.user_id)

      patch vote_burn_unit_game_player_path(game.id), params: {
        player: {
          candidate_id: ""
        }
      }

      assert_response :unprocessable_content
      assert_dom "select[aria-label='Vote for player']"
    end

    test "#vote redirects to new player when current player is nil" do
      game = create(:bu_game)
      user = create(:user)
      sign_in(user.id)

      patch vote_burn_unit_game_player_path(game.id), params: {
        player: {
          candidate_id: "some-id"
        }
      }

      assert_redirected_to new_burn_unit_game_player_path(game.id)
    end

    test "#vote renders polling_judge view for judge" do
      game = create(:bu_polling_game, player_names: %w[Bob])
      judge = game.players.find(&:judge?)
      bob = game.players.find { |p| p.name.to_s == "Bob" }
      sign_in(judge.user_id)

      patch vote_burn_unit_game_player_path(game.id), params: {
        player: {
          candidate_id: bob.id
        }
      }

      assert_response :ok
      assert_dom "button", text: "Tally Votes"
    end

    test "#vote renders polling_player view for non-judge" do
      game = create(:bu_polling_game, player_names: %w[Bob])
      bob = game.players.find { |p| p.name.to_s == "Bob" }
      judge = game.players.find(&:judge?)
      sign_in(bob.user_id)

      patch vote_burn_unit_game_player_path(game.id), params: {
        player: {
          candidate_id: judge.id
        }
      }

      assert_response :ok
      assert_not_dom "button", text: "Tally Votes"
    end

    test "#create creates player and redirects to game" do
      game = create(:bu_game)
      user = create(:user)
      sign_in(user.id)

      assert_difference "::Player.count", 1 do
        post burn_unit_game_player_path(game.id), params: {
          player: {
            name: "Charlie"
          }
        }
      end

      assert_response :redirect
      assert_redirected_to burn_unit_game_path(game.id)
    end

    test "#create renders form with validation errors" do
      game = create(:bu_game)
      user = create(:user)
      sign_in(user.id)

      post burn_unit_game_player_path(game.id), params: {
        player: {
          name: "ab"
        }
      }

      assert_response :unprocessable_content
      assert_dom "input[name='player[name]']"
      assert_match(/is too short/, response.body)
    end

    test "#new renders new player form when user not in game" do
      game = create(:bu_game)
      user = create(:user)
      sign_in(user.id)

      get new_burn_unit_game_player_path(game.id)

      assert_response :success
      assert_dom "input[name='player[name]']"
    end

    test "#new redirects to game when user already in game" do
      game = create(:bu_polling_game)
      judge = game.players.find(&:judge?)
      sign_in(judge.user_id)

      get new_burn_unit_game_player_path(game.id)

      assert_response :redirect
      assert_redirected_to burn_unit_game_path(game.id)
    end

    test "#edit renders edit player form for current player" do
      game = create(:bu_polling_game)
      judge = game.players.find(&:judge?)
      sign_in(judge.user_id)

      get edit_burn_unit_game_player_path(game.id)

      assert_response :success
      assert_dom "input[name='player[name]']"
      assert_dom "input[type='submit'][value='Update Name']"
    end

    test "#edit populates form with current player name" do
      game = create(:bu_polling_game, player_names: %w[Alice Bob])
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      sign_in(alice.user_id)

      get edit_burn_unit_game_player_path(game.id)

      assert_response :success
      assert_dom "input[name='player[name]'][value='Alice']"
    end

    test "#edit redirects to new player when current player is nil" do
      game = create(:bu_game)
      user = create(:user)
      sign_in(user.id)

      get edit_burn_unit_game_player_path(game.id)

      assert_redirected_to new_burn_unit_game_player_path(game.id)
    end

    test "#update updates player name and redirects to game" do
      game = create(:bu_polling_game, player_names: %w[Alice Bob])
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      sign_in(alice.user_id)

      patch burn_unit_game_player_path(game.id), params: {
        player: {
          name: "Alicia"
        }
      }

      assert_redirected_to burn_unit_game_path(game.id)
      game = reload(game:)
      updated_player = game.player_for(alice.user_id)
      assert_equal "Alicia", updated_player.name.to_s
    end

    test "#update returns validation error for short name" do
      game = create(:bu_polling_game, player_names: %w[Alice Bob])
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      sign_in(alice.user_id)

      patch burn_unit_game_player_path(game.id), params: {
        player: {
          name: "Al"
        }
      }

      assert_response :unprocessable_content
      assert_dom "input[name='player[name]']"
      assert_match(/is too short/, response.body)
    end

    test "#update returns validation error for duplicate name" do
      game = create(:bu_polling_game, player_names: %w[Alice Bob])
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      sign_in(alice.user_id)

      patch burn_unit_game_player_path(game.id), params: {
        player: {
          name: "bob"
        }
      }

      assert_response :unprocessable_content
      assert_dom "input[name='player[name]']"
      assert_match(/has already been taken/, response.body)
    end

    test "#update redirects to new player when current player is nil" do
      game = create(:bu_game)
      user = create(:user)
      sign_in(user.id)

      patch burn_unit_game_player_path(game.id), params: {
        player: {
          name: "Charlie"
        }
      }

      assert_redirected_to new_burn_unit_game_player_path(game.id)
    end
  end
end
