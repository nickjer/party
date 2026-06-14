# frozen_string_literal: true

require "test_helper"

module Wavelength
  class GamesControllerTest < ActionDispatch::IntegrationTest
    test "#new renders the new game form" do
      sign_in(create(:user).id)

      get new_wavelength_game_path

      assert_response :success
      assert_dom "input[name='game[player_name]']"
    end

    test "#create builds a game and joins the creator" do
      sign_in(create(:user).id)

      assert_difference -> { ::Game.wavelength.count } => 1 do
        post wavelength_games_path, params: { game: { player_name: "Alice" } }
      end

      assert_response :redirect
    end

    test "#create re-renders on invalid name" do
      sign_in(create(:user).id)

      post wavelength_games_path, params: { game: { player_name: "ab" } }

      assert_response :unprocessable_content
    end

    test "#show redirects to new player when not in the game" do
      game = create(:wl_game)
      sign_in(create(:user).id)

      get wavelength_game_path(game.id)

      assert_redirected_to new_wavelength_game_player_path(game.id)
    end

    test "#show renders the lobby during setup" do
      game = create(:wl_game, :with_teams)
      sign_in(player_named(game, "RedOne").user_id)

      get wavelength_game_path(game.id)

      assert_response :success
      assert_dom "#team_panels"
    end

    test "#show renders the play area while guessing" do
      game = create(:wl_guessing_game)
      sign_in(player_named(game, "RedOne").user_id)

      get wavelength_game_path(game.id)

      assert_response :success
      assert_dom "#play_area"
    end

    test "#show shows the join gate to a teamless player mid-game" do
      game = create(:wl_guessing_game)
      latecomer = game.add_player(user_id: create(:user).id,
        name: PlayerName.parse("Late"))
      GameRepo.save(game)
      sign_in(latecomer.user_id)

      get wavelength_game_path(game.id)

      assert_response :success
      assert_dom "button", text: /Join Red/
    end

    test "#show renders the play area for a completed game" do
      game = create(:wl_completed_game)
      sign_in(player_named(game, "RedOne").user_id)

      get wavelength_game_path(game.id)

      assert_response :success
      assert_dom "#play_area"
    end

    test "#start transitions to guessing and makes the clicker psychic" do
      game = create(:wl_game, :with_teams)
      red = player_named(game, "RedOne")
      sign_in(red.user_id)

      post start_wavelength_game_path(game.id)

      assert_response :success
      assert_predicate reload(game:).status, :guessing?
      assert_equal red.id, reload(game:).psychic.id
    end

    test "#start is forbidden for a player not on the starting team" do
      game = create(:wl_game, :with_teams) # red starts
      sign_in(player_named(game, "BlueOne").user_id)

      post start_wavelength_game_path(game.id)

      assert_response :forbidden
    end

    test "#start re-renders the lobby when the teams are incomplete" do
      game = create(:wl_game)
      user = create(:user)
      game.add_player(user_id: user.id, name: PlayerName.parse("RedOne"),
        team: Team.red)
      GameRepo.save(game)
      sign_in(user.id)

      post start_wavelength_game_path(game.id)

      assert_response :unprocessable_content
      assert_dom ".alert", text: /at least 2 players/
      assert_predicate reload(game:).status, :setup?
    end

    test "#move_dial is forbidden when the game is not guessing" do
      game = create(:wl_game, :with_teams) # still in setup
      sign_in(player_named(game, "RedTwo").user_id)

      patch move_dial_wavelength_game_path(game.id),
        params: { guess: { position: 30 } }

      assert_response :forbidden
    end

    test "#move_dial is forbidden for an off-team player" do
      game = create(:wl_guessing_game) # red's turn
      sign_in(player_named(game, "BlueOne").user_id)

      patch move_dial_wavelength_game_path(game.id),
        params: { guess: { position: 30 } }

      assert_response :forbidden
    end

    test "#move_dial is forbidden for the psychic" do
      game = create(:wl_guessing_game)
      sign_in(game.psychic.user_id)

      patch move_dial_wavelength_game_path(game.id),
        params: { guess: { position: 30 } }

      assert_response :forbidden
    end

    test "#move_dial is forbidden for an out-of-range position" do
      game = create(:wl_guessing_game)
      sign_in(game.guessers.first.user_id)

      patch move_dial_wavelength_game_path(game.id),
        params: { guess: { position: 150 } }

      assert_response :forbidden
    end

    test "#move_dial is forbidden for a non-numeric position" do
      game = create(:wl_guessing_game)
      sign_in(game.guessers.first.user_id)

      patch move_dial_wavelength_game_path(game.id),
        params: { guess: { position: "abc" } }

      assert_response :forbidden
    end

    test "#move_dial slides the dial for an active guesser" do
      game = create(:wl_guessing_game)
      sign_in(game.guessers.first.user_id)

      patch move_dial_wavelength_game_path(game.id),
        params: { guess: { position: 30 } }

      assert_response :no_content
      assert_predicate reload(game:).status, :guessing?
      assert_equal 30, reload(game:).guess
    end

    test "#lock_guess is forbidden when the game is not guessing" do
      game = create(:wl_game, :with_teams) # still in setup
      sign_in(player_named(game, "RedTwo").user_id)

      patch lock_guess_wavelength_game_path(game.id),
        params: { guess: { position: 50 } }

      assert_response :forbidden
    end

    test "#lock_guess is forbidden for an off-team player" do
      game = create(:wl_guessing_game) # red's turn
      sign_in(player_named(game, "BlueOne").user_id)

      patch lock_guess_wavelength_game_path(game.id),
        params: { guess: { position: 50 } }

      assert_response :forbidden
    end

    test "#lock_guess is forbidden for the psychic" do
      game = create(:wl_guessing_game)
      sign_in(game.psychic.user_id)

      patch lock_guess_wavelength_game_path(game.id),
        params: { guess: { position: 50 } }

      assert_response :forbidden
    end

    test "#lock_guess is forbidden for an out-of-range position" do
      game = create(:wl_guessing_game)
      sign_in(game.guessers.first.user_id)

      patch lock_guess_wavelength_game_path(game.id),
        params: { guess: { position: 150 } }

      assert_response :forbidden
    end

    test "#lock_guess is forbidden for a non-numeric position" do
      game = create(:wl_guessing_game)
      sign_in(game.guessers.first.user_id)

      patch lock_guess_wavelength_game_path(game.id),
        params: { guess: { position: "abc" } }

      assert_response :forbidden
    end

    test "#lock_guess locks the dial for an active guesser" do
      game = create(:wl_guessing_game)
      sign_in(game.guessers.first.user_id)

      patch lock_guess_wavelength_game_path(game.id),
        params: { guess: { position: 42 } }

      assert_response :success
      assert_predicate reload(game:).status, :left_right?
      assert_equal 42, reload(game:).guess
    end

    test "#guess_side is forbidden when the game is not in left_right" do
      game = create(:wl_guessing_game)
      sign_in(player_named(game, "BlueOne").user_id)

      patch guess_side_wavelength_game_path(game.id),
        params: { guess: { side: "left" } }

      assert_response :forbidden
    end

    test "#guess_side is forbidden for a player on the active team" do
      game = create(:wl_left_right_game) # red active, blue guesses side
      sign_in(player_named(game, "RedOne").user_id)

      patch guess_side_wavelength_game_path(game.id),
        params: { guess: { side: "left" } }

      assert_response :forbidden
    end

    test "#guess_side is forbidden for an unknown side" do
      game = create(:wl_left_right_game)
      sign_in(player_named(game, "BlueOne").user_id)

      patch guess_side_wavelength_game_path(game.id),
        params: { guess: { side: "up" } }

      assert_response :forbidden
    end

    test "#guess_side scores the round and reveals" do
      game = create(:wl_left_right_game)
      sign_in(player_named(game, "BlueOne").user_id)

      patch guess_side_wavelength_game_path(game.id),
        params: { guess: { side: "left" } }

      assert_response :success
      assert_predicate reload(game:).status, :reveal?
    end

    test "#next_round is forbidden unless the game is in reveal" do
      game = create(:wl_guessing_game)
      sign_in(player_named(game, "RedOne").user_id)

      post next_round_wavelength_game_path(game.id)

      assert_response :forbidden
    end

    test "#next_round starts the next round and makes the clicker psychic" do
      game = create(:wl_reveal_game) # red just played, blue is up
      blue = player_named(game, "BlueOne")
      sign_in(blue.user_id)

      post next_round_wavelength_game_path(game.id)

      assert_response :success
      assert_predicate reload(game:).status, :guessing?
      assert_equal Team.blue, reload(game:).current_team
      assert_equal blue.id, reload(game:).psychic.id
    end

    test "#next_round is forbidden for a player not on the up team" do
      game = create(:wl_reveal_game) # red just played, blue is up
      sign_in(player_named(game, "RedOne").user_id)

      post next_round_wavelength_game_path(game.id)

      assert_response :forbidden
    end

    test "#new_game resets a completed game to the lobby" do
      game = create(:wl_completed_game)
      sign_in(player_named(game, "RedOne").user_id)

      post new_game_wavelength_game_path(game.id)

      assert_response :success
      assert_predicate reload(game:).status, :setup?
    end

    test "#new_game is forbidden unless the game is completed" do
      game = create(:wl_guessing_game)
      sign_in(player_named(game, "RedOne").user_id)

      post new_game_wavelength_game_path(game.id)

      assert_response :forbidden
    end

    private

    def player_named(game, name)
      game.players.find { |player| player.name.to_s == name }
    end
  end
end
