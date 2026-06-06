# frozen_string_literal: true

require "test_helper"

module Codenames
  class PlayersControllerTest < ActionDispatch::IntegrationTest
    test "#new renders the join form for a new user" do
      game = create(:cn_game)
      sign_in(create(:user).id)

      get new_codenames_game_player_path(game.id)

      assert_response :success
      assert_dom "input[name='player[name]']"
    end

    test "#new redirects an existing player to the game" do
      game = create(:cn_game, :with_teams)
      sign_in(game.spymaster_for(Team.red).user_id)

      get new_codenames_game_player_path(game.id)

      assert_redirected_to codenames_game_path(game.id)
    end

    test "#create adds a teamless player" do
      game = create(:cn_game)
      sign_in(create(:user).id)

      post codenames_game_player_path(game.id),
        params: { player: { name: "Alice" } }

      assert_redirected_to codenames_game_path(game.id)
      assert_equal 1, reload(game:).players.size
    end

    test "#create re-renders on an invalid name" do
      game = create(:cn_game)
      sign_in(create(:user).id)

      post codenames_game_player_path(game.id),
        params: { player: { name: "ab" } }

      assert_response :unprocessable_content
      assert_match(/too short/, response.body)
    end

    test "#edit redirects to the join form when not in the game" do
      game = create(:cn_game)
      sign_in(create(:user).id)

      get edit_codenames_game_player_path(game.id)

      assert_redirected_to new_codenames_game_player_path(game.id)
    end

    test "#edit renders the name form for an existing player" do
      game = create(:cn_game, :with_teams)
      sign_in(game.spymaster_for(Team.red).user_id)

      get edit_codenames_game_player_path(game.id)

      assert_response :success
      assert_dom "input[name='player[name]']"
    end

    test "#update redirects to the join form when not in the game" do
      game = create(:cn_game)
      sign_in(create(:user).id)

      patch codenames_game_player_path(game.id),
        params: { player: { name: "Renamed" } }

      assert_redirected_to new_codenames_game_player_path(game.id)
    end

    test "#update renames an existing player" do
      game = create(:cn_game, :with_teams)
      player = game.spymaster_for(Team.red)
      sign_in(player.user_id)

      patch codenames_game_player_path(game.id),
        params: { player: { name: "Renamed" } }

      assert_redirected_to codenames_game_path(game.id)
      assert_equal "Renamed",
        reload(game:).player_for(player.user_id).name.to_s
    end

    test "#update re-renders on an invalid name" do
      game = create(:cn_game, :with_teams)
      sign_in(game.spymaster_for(Team.red).user_id)

      patch codenames_game_player_path(game.id),
        params: { player: { name: "ab" } }

      assert_response :unprocessable_content
      assert_match(/too short/, response.body)
    end

    test "#join_team redirects to the join form when not in the game" do
      game = create(:cn_game)
      sign_in(create(:user).id)

      patch join_team_codenames_game_player_path(game.id),
        params: { player: { team: "red", spymaster: "false" } }

      assert_redirected_to new_codenames_game_player_path(game.id)
    end

    test "#join_team assigns a team and role during setup" do
      game = create(:cn_game)
      user = create(:user)
      sign_in(user.id)
      post codenames_game_player_path(game.id),
        params: { player: { name: "Alice" } }

      patch join_team_codenames_game_player_path(game.id),
        params: { player: { team: "red", spymaster: "true" } }

      player = reload(game:).player_for(user.id)
      assert_equal Team.red, player.team
      assert_predicate player, :spymaster?
    end

    test "#join_team re-renders the lobby when the spymaster seat is taken" do
      game = create(:cn_game, :with_teams) # red spymaster taken
      user = create(:user)
      sign_in(user.id)
      post codenames_game_player_path(game.id),
        params: { player: { name: "Late" } }

      patch join_team_codenames_game_player_path(game.id),
        params: { player: { team: "red", spymaster: "true" } }

      assert_response :unprocessable_content
      assert_match(/already has a spymaster/, response.body)
    end

    test "#join_team lets a teamless player join mid-game as an operative" do
      game = create(:cn_playing_game)
      user = create(:user)
      sign_in(user.id)
      post codenames_game_player_path(game.id),
        params: { player: { name: "Late" } }

      patch join_team_codenames_game_player_path(game.id),
        params: { player: { team: "blue", spymaster: "false" } }

      assert_redirected_to codenames_game_path(game.id)
      assert_equal Team.blue, reload(game:).player_for(user.id).team
    end

    test "#join_team re-renders the gate when a latecomer picks spymaster" do
      game = create(:cn_playing_game)
      user = create(:user)
      sign_in(user.id)
      post codenames_game_player_path(game.id),
        params: { player: { name: "Late" } }

      patch join_team_codenames_game_player_path(game.id),
        params: { player: { team: "blue", spymaster: "true" } }

      assert_response :unprocessable_content
      assert_match(/roles are locked/, response.body)
    end

    test "#join_team tells a latecomer the game is over once completed" do
      game = create(:cn_completed_game)
      user = create(:user)
      sign_in(user.id)
      post codenames_game_player_path(game.id),
        params: { player: { name: "Late" } }

      patch join_team_codenames_game_player_path(game.id),
        params: { player: { team: "blue", spymaster: "false" } }

      assert_response :unprocessable_content
      assert_match(/Game is over/, response.body)
    end
  end
end
