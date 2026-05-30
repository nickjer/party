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

    test "#create adds a teamless player" do
      game = create(:cn_game)
      sign_in(create(:user).id)

      post codenames_game_player_path(game.id),
        params: { player: { name: "Alice" } }

      assert_redirected_to codenames_game_path(game.id)
      assert_equal 1, reload(game:).players.size
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

    test "#join_team re-renders the lobby with errors on a taken spymaster seat" do
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
  end
end
