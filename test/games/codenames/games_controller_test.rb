# frozen_string_literal: true

require "test_helper"

module Codenames
  class GamesControllerTest < ActionDispatch::IntegrationTest
    test "#new renders the new game form" do
      sign_in(create(:user).id)

      get new_codenames_game_path

      assert_response :success
      assert_dom "input[name='game[player_name]']"
    end

    test "#create builds a game and joins the creator" do
      sign_in(create(:user).id)

      assert_difference -> { ::Game.codenames.count } => 1 do
        post codenames_games_path, params: { game: { player_name: "Alice" } }
      end

      assert_response :redirect
    end

    test "#create re-renders on invalid name" do
      sign_in(create(:user).id)

      post codenames_games_path, params: { game: { player_name: "ab" } }

      assert_response :unprocessable_content
    end

    test "#show redirects to new player when not in the game" do
      game = create(:cn_game)
      sign_in(create(:user).id)

      get codenames_game_path(game.id)

      assert_redirected_to new_codenames_game_player_path(game.id)
    end

    test "#show renders the lobby during setup" do
      game = create(:cn_game, :with_teams)
      sign_in(game.spymaster_for(Team.red).user_id)

      get codenames_game_path(game.id)

      assert_response :success
      assert_dom "#team_panels"
    end

    test "#show renders the board while playing" do
      game = create(:cn_playing_game)
      sign_in(red_operative(game).user_id)

      get codenames_game_path(game.id)

      assert_response :success
      assert_dom "#play_area"
    end

    test "#show shows the join gate to a teamless player mid-game" do
      game = create(:cn_playing_game)
      latecomer = game.add_player(user_id: create(:user).id,
        name: PlayerName.parse("Late"))
      Codenames::GameRepo.save(game)
      sign_in(latecomer.user_id)

      get codenames_game_path(game.id)

      assert_response :success
      assert_dom "button", text: /Join Red/
    end

    test "#show renders the board for a completed game" do
      game = create(:cn_completed_game)
      sign_in(red_operative(game).user_id)

      get codenames_game_path(game.id)

      assert_response :success
      assert_dom "#play_area"
    end

    test "#show raises on an unknown game status" do
      game = create(:cn_game, :with_teams)
      sign_in(game.spymaster_for(Team.red).user_id)
      game.stubs(:status).returns(Game::Status.send(:new, :bogus))
      GameRepo.stubs(:find).returns(game)

      assert_raises(RuntimeError) { get codenames_game_path(game.id) }
    end

    test "#start is forbidden for a non-starting-spymaster" do
      game = create(:cn_game, :with_teams)
      sign_in(red_operative(game).user_id)

      post start_codenames_game_path(game.id)

      assert_response :forbidden
    end

    test "#start transitions the game to playing" do
      game = create(:cn_game, :with_teams) # red starts
      sign_in(game.spymaster_for(Team.red).user_id)

      post start_codenames_game_path(game.id)

      assert_response :success
      assert_predicate reload(game:).status, :playing?
    end

    test "#start re-renders the lobby when the teams are incomplete" do
      game = create(:cn_game) # red starts, no players yet
      user = create(:user)
      game.add_player(user_id: user.id, name: PlayerName.parse("RedSpy"),
        team: Team.red, spymaster: true)
      GameRepo.save(game)
      sign_in(user.id)

      post start_codenames_game_path(game.id)

      assert_response :unprocessable_content
      assert_predicate reload(game:).status, :setup?
    end

    test "#submit_clue stores the clue for the active spymaster" do
      game = create(:cn_playing_game) # red's turn
      sign_in(game.spymaster_for(Team.red).user_id)

      patch submit_clue_codenames_game_path(game.id),
        params: { clue: { word: "Ocean", number: "2" } }

      assert_response :success
      clue = reload(game:).clue
      assert_equal "Ocean", clue.word.to_s
      assert_equal 2, clue.number
    end

    test "#submit_clue stores an unlimited clue" do
      game = create(:cn_playing_game)
      sign_in(game.spymaster_for(Team.red).user_id)

      patch submit_clue_codenames_game_path(game.id),
        params: { clue: { word: "Ocean", number: "unlimited" } }

      assert_response :success
      assert_predicate reload(game:).clue, :unlimited?
    end

    test "#submit_clue is forbidden for an operative" do
      game = create(:cn_playing_game)
      sign_in(red_operative(game).user_id)

      patch submit_clue_codenames_game_path(game.id),
        params: { clue: { word: "Ocean", number: "2" } }

      assert_response :forbidden
    end

    test "#submit_clue is forbidden for the off-turn spymaster" do
      game = create(:cn_playing_game) # red's turn
      sign_in(game.spymaster_for(Team.blue).user_id)

      patch submit_clue_codenames_game_path(game.id),
        params: { clue: { word: "Ocean", number: "2" } }

      assert_response :forbidden
    end

    test "#submit_clue is forbidden when the game is not playing" do
      game = create(:cn_game, :with_teams) # still in setup
      sign_in(game.spymaster_for(Team.red).user_id)

      patch submit_clue_codenames_game_path(game.id),
        params: { clue: { word: "Ocean", number: "2" } }

      assert_response :forbidden
    end

    test "#submit_clue is forbidden when a clue is already submitted" do
      game = create(:cn_guessing_game)
      sign_in(game.spymaster_for(Team.red).user_id)

      patch submit_clue_codenames_game_path(game.id),
        params: { clue: { word: "Ocean", number: "2" } }

      assert_response :forbidden
    end

    test "#submit_clue re-renders on a blank word" do
      game = create(:cn_playing_game)
      sign_in(game.spymaster_for(Team.red).user_id)

      patch submit_clue_codenames_game_path(game.id),
        params: { clue: { word: "", number: "2" } }

      assert_response :unprocessable_content
      assert_dom ".invalid-feedback", text: /too short/
      assert_nil reload(game:).clue
    end

    test "#submit_clue re-renders on an invalid number" do
      game = create(:cn_playing_game)
      sign_in(game.spymaster_for(Team.red).user_id)

      patch submit_clue_codenames_game_path(game.id),
        params: { clue: { word: "Ocean", number: "10" } }

      assert_response :unprocessable_content
      assert_dom ".invalid-feedback", text: /must be 0-9 or unlimited/
      assert_nil reload(game:).clue
    end

    test "#reveal is forbidden for an off-turn operative" do
      game = create(:cn_guessing_game) # red's turn
      blue_op = game.players.find { |player| player.name.to_s == "BlueOp" }
      sign_in(blue_op.user_id)
      index = game.board.cards.index { |card| card.identity.team == Team.red }

      patch reveal_codenames_game_path(game.id),
        params: { reveal: { index: } }

      assert_response :forbidden
    end

    test "#reveal is forbidden for a spymaster" do
      game = create(:cn_guessing_game)
      sign_in(game.spymaster_for(Team.red).user_id)

      patch reveal_codenames_game_path(game.id),
        params: { reveal: { index: 0 } }

      assert_response :forbidden
    end

    test "#reveal flips a card for the active operative" do
      game = create(:cn_guessing_game)
      sign_in(red_operative(game).user_id)
      index = game.board.cards.index { |card| card.identity.team == Team.red }

      patch reveal_codenames_game_path(game.id),
        params: { reveal: { index: } }

      assert_response :success
      assert_predicate reload(game:).board.card(index), :revealed?
    end

    test "#reveal is forbidden for a non-numeric index" do
      game = create(:cn_guessing_game)
      sign_in(red_operative(game).user_id)

      patch reveal_codenames_game_path(game.id),
        params: { reveal: { index: "abc" } }

      assert_response :forbidden
      assert_not reload(game:).board.card(0).revealed?
    end

    test "#reveal is forbidden when the game is not playing" do
      game = create(:cn_game, :with_teams) # still in setup
      sign_in(red_operative(game).user_id)

      patch reveal_codenames_game_path(game.id),
        params: { reveal: { index: 0 } }

      assert_response :forbidden
    end

    test "#reveal is forbidden when no clue is submitted" do
      game = create(:cn_playing_game)
      sign_in(red_operative(game).user_id)

      patch reveal_codenames_game_path(game.id),
        params: { reveal: { index: 0 } }

      assert_response :forbidden
      assert_not reload(game:).board.card(0).revealed?
    end

    test "#pass switches the turn" do
      game = create(:cn_guessing_game)
      index = game.board.cards.index { |card| card.identity.team == Team.red }
      game.reveal(index:)
      GameRepo.save(game)
      sign_in(red_operative(game).user_id)

      patch pass_codenames_game_path(game.id)

      assert_response :success
      assert_equal Team.blue, reload(game:).current_team
    end

    test "#pass is forbidden when the game is not playing" do
      game = create(:cn_game, :with_teams) # still in setup
      sign_in(red_operative(game).user_id)

      patch pass_codenames_game_path(game.id)

      assert_response :forbidden
    end

    test "#pass is forbidden for a spymaster" do
      game = create(:cn_guessing_game)
      sign_in(game.spymaster_for(Team.red).user_id)

      patch pass_codenames_game_path(game.id)

      assert_response :forbidden
    end

    test "#pass is forbidden for an off-turn operative" do
      game = create(:cn_guessing_game) # red's turn
      blue_op = game.players.find { |player| player.name.to_s == "BlueOp" }
      sign_in(blue_op.user_id)

      patch pass_codenames_game_path(game.id)

      assert_response :forbidden
    end

    test "#pass is forbidden when no clue is submitted" do
      game = create(:cn_playing_game)
      sign_in(red_operative(game).user_id)

      patch pass_codenames_game_path(game.id)

      assert_response :forbidden
    end

    test "#pass is forbidden before the team has guessed" do
      game = create(:cn_guessing_game)
      sign_in(red_operative(game).user_id)

      patch pass_codenames_game_path(game.id)

      assert_response :forbidden
      assert_equal Team.red, reload(game:).current_team
    end

    test "#new_game resets a completed game to the lobby" do
      game = create(:cn_completed_game)
      sign_in(game.spymaster_for(Team.red).user_id)

      post new_game_codenames_game_path(game.id)

      assert_response :success
      assert_predicate reload(game:).status, :setup?
    end

    test "#new_game is forbidden unless the game is completed" do
      game = create(:cn_playing_game)
      sign_in(game.spymaster_for(Team.red).user_id)

      post new_game_codenames_game_path(game.id)

      assert_response :forbidden
    end

    private

    def red_operative(game)
      game.players.find { |player| player.name.to_s == "RedOp" }
    end
  end
end
