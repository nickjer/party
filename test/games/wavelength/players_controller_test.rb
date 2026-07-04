# frozen_string_literal: true

require "test_helper"

module Wavelength
  class PlayersControllerTest < ActionDispatch::IntegrationTest
    test "#new renders the join form for a new user" do
      game = create(:wl_game)
      sign_in(create(:user).id)

      get new_wavelength_game_player_path(game.id)

      assert_response :success
      assert_dom "input[name='player[name]']"
    end

    test "#new redirects an existing player to the game" do
      game = create(:wl_game, :with_teams)
      sign_in(player_named(game:, name: "RedOne").user_id)

      get new_wavelength_game_player_path(game.id)

      assert_redirected_to wavelength_game_path(game.id)
    end

    test "#create adds a teamless player" do
      game = create(:wl_game)
      sign_in(create(:user).id)

      post wavelength_game_player_path(game.id),
        params: { player: { name: "Alice" } }

      assert_redirected_to wavelength_game_path(game.id)
      assert_equal 1, reload(game:).players.size
    end

    test "#create re-renders on an invalid name" do
      game = create(:wl_game)
      sign_in(create(:user).id)

      post wavelength_game_player_path(game.id),
        params: { player: { name: "ab" } }

      assert_response :unprocessable_content
      assert_match(/too short/, response.body)
    end

    test "#edit redirects to the join form when not in the game" do
      game = create(:wl_game)
      sign_in(create(:user).id)

      get edit_wavelength_game_player_path(game.id)

      assert_redirected_to new_wavelength_game_player_path(game.id)
    end

    test "#edit renders the name form for an existing player" do
      game = create(:wl_game, :with_teams)
      sign_in(player_named(game:, name: "RedOne").user_id)

      get edit_wavelength_game_player_path(game.id)

      assert_response :success
      assert_dom "input[name='player[name]']"
    end

    test "#update redirects to the join form when not in the game" do
      game = create(:wl_game)
      sign_in(create(:user).id)

      patch wavelength_game_player_path(game.id),
        params: { player: { name: "Renamed" } }

      assert_redirected_to new_wavelength_game_player_path(game.id)
    end

    test "#update renames an existing player" do
      game = create(:wl_game, :with_teams)
      player = player_named(game:, name: "RedOne")
      sign_in(player.user_id)

      patch wavelength_game_player_path(game.id),
        params: { player: { name: "Renamed" } }

      assert_redirected_to wavelength_game_path(game.id)
      assert_equal "Renamed",
        reload(game:).player_for(player.user_id).name.to_s
    end

    test "#update re-renders on an invalid name" do
      game = create(:wl_game, :with_teams)
      sign_in(player_named(game:, name: "RedOne").user_id)

      patch wavelength_game_player_path(game.id),
        params: { player: { name: "ab" } }

      assert_response :unprocessable_content
      assert_match(/too short/, response.body)
    end

    test "#join_team redirects to the join form when not in the game" do
      game = create(:wl_game)
      sign_in(create(:user).id)

      patch join_team_wavelength_game_player_path(game.id),
        params: { player: { team: "red" } }

      assert_redirected_to new_wavelength_game_player_path(game.id)
    end

    test "#join_team assigns a team during setup" do
      game = create(:wl_game)
      user = create(:user)
      sign_in(user.id)
      post wavelength_game_player_path(game.id),
        params: { player: { name: "Alice" } }

      patch join_team_wavelength_game_player_path(game.id),
        params: { player: { team: "red" } }

      assert_redirected_to wavelength_game_path(game.id)
      assert_equal Team.red, reload(game:).player_for(user.id).team
    end

    test "#join_team re-renders the lobby on an unknown team during setup" do
      game = create(:wl_game)
      user = create(:user)
      sign_in(user.id)
      post wavelength_game_player_path(game.id),
        params: { player: { name: "Alice" } }

      patch join_team_wavelength_game_player_path(game.id),
        params: { player: { team: "green" } }

      assert_response :unprocessable_content
      assert_match(/must be red or blue/, response.body)
    end

    test "#join_team lets a teamless player join mid-game" do
      game = create(:wl_guessing_game)
      user = create(:user)
      sign_in(user.id)
      post wavelength_game_player_path(game.id),
        params: { player: { name: "Late" } }

      patch join_team_wavelength_game_player_path(game.id),
        params: { player: { team: "blue" } }

      assert_redirected_to wavelength_game_path(game.id)
      assert_equal Team.blue, reload(game:).player_for(user.id).team
    end

    test "#join_team re-renders the gate when switching teams mid-game" do
      game = create(:wl_guessing_game)
      player = player_named(game:, name: "RedOne")
      sign_in(player.user_id)

      patch join_team_wavelength_game_player_path(game.id),
        params: { player: { team: "blue" } }

      assert_response :unprocessable_content
      assert_match(/Teams are locked/, response.body)
    end

    test "#join_team tells a latecomer the game is over once completed" do
      game = create(:wl_completed_game)
      user = create(:user)
      sign_in(user.id)
      post wavelength_game_player_path(game.id),
        params: { player: { name: "Late" } }

      patch join_team_wavelength_game_player_path(game.id),
        params: { player: { team: "blue" } }

      assert_response :unprocessable_content
      assert_match(/Game is over/, response.body)
    end
  end
end
