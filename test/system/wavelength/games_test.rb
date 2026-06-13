# frozen_string_literal: true

require "application_system_test_case"

module Wavelength
  class GamesTest < ApplicationSystemTestCase
    test "teams form, play a full game across sessions, and start over" do
      # Ada creates the game and lands in the lobby (teamless).
      visit new_wavelength_game_path
      fill_in "Your Name", with: "Ada"
      click_on "Create New Game"

      assert_selector "#team_panels"
      game_id = current_path.split("/").last

      # Not enough players yet — no Start game button.
      assert_no_button "Start game"
      assert_text "Each team needs at least two players"

      # Ada joins the red team.
      within "div.card.border-danger" do
        click_on "Join"
      end
      within "div.card.border-danger" do
        assert_text "Ada", wait: 5
      end

      # Ben joins red as the second member.
      using_session("ben") do
        visit new_wavelength_game_player_path(game_id)
        fill_in "Your Name", with: "Ben"
        click_on "Join Game"
        within("div.card.border-danger") { click_on "Join" }
      end

      # Ada sees Ben appear on the red team in real time.
      within "div.card.border-danger" do
        assert_text "Ben", wait: 5
      end

      # Cleo and Dana fill out the blue team.
      using_session("cleo") do
        visit new_wavelength_game_player_path(game_id)
        fill_in "Your Name", with: "Cleo"
        click_on "Join Game"
        within("div.card.border-primary") { click_on "Join" }
      end

      using_session("dana") do
        visit new_wavelength_game_player_path(game_id)
        fill_in "Your Name", with: "Dana"
        click_on "Join Game"
        within("div.card.border-primary") { click_on "Join" }
      end

      # With two per team, every player now sees the Start game button.
      assert_button "Start game", wait: 5
      using_session("cleo") { assert_button "Start game", wait: 5 }

      # Ada starts the game.
      click_on "Start game"
      assert_selector "#play_area", wait: 5
      assert_text "Red team's turn"

      # ---- Round 1, played out in full with cross-session broadcasts ----
      game = GameRepo.find(game_id) # red starts
      psychic = game.psychic
      guesser = game.guessers.first
      opponent = game.players_on(Team.blue).first
      target = game.target.position

      # The psychic sees the target and is told to give a clue.
      using_session(session_for(psychic)) do
        assert_text "Give your one-word clue out loud!", wait: 5
        assert_no_button "Lock it in"
      end

      # An opponent waits while the red team guesses (no dial controls).
      using_session(session_for(opponent)) do
        assert_text "guessing", wait: 5
        assert_no_button "Lock it in"
        assert_no_button "← Left"
      end

      # The active guesser drags the dial onto the target and locks it in.
      using_session(session_for(guesser)) do
        assert_button "Lock it in", wait: 5
        lock_dial(target)
        assert_text "Waiting", wait: 5 # active team now waits on the opponent
      end

      # The opponent now sees the left/right catch-up via broadcast.
      using_session(session_for(opponent)) do
        assert_text "Is the target left or right", wait: 5
        click_on "← Left"
        # Wait for the reveal before reading state (the PATCH is async).
        assert_button "Next round", wait: 5
      end

      # A bullseye scores 4 for red; the exact target means the opponent's
      # left/right guess can never be right, so blue stays at 0.
      assert_equal 4, GameRepo.find(game_id).score_for(Team.red)
      assert_equal 0, GameRepo.find(game_id).score_for(Team.blue)

      # Everyone lands on the reveal with a Next round button (broadcast).
      using_session(session_for(psychic)) do
        assert_button "Next round", wait: 5
      end
      using_session(session_for(opponent)) do
        click_on "Next round"
      end

      # The turn passes to blue and a fresh psychic is on the blue team.
      using_session(session_for(guesser)) do
        assert_text "Blue team's turn", wait: 5
      end
      assert_equal Team.blue, GameRepo.find(game_id).current_team

      # ---- Drive the remaining rounds until red reaches the win score ----
      loop do
        game = GameRepo.find(game_id)
        break if game.status.completed?

        guesser = game.guessers.first
        opponent = game.players_on(game.current_team.opponent).first
        target = game.target.position

        using_session(session_for(guesser)) do
          assert_button "Lock it in", wait: 5
          lock_dial(target)
          assert_text "Waiting", wait: 5
        end

        completed = false
        using_session(session_for(opponent)) do
          assert_text "Is the target left or right", wait: 5
          click_on "← Left"
          # The round ends on either a reveal or, on the winning turn, the
          # completed banner. Wait for whichever lands.
          assert_selector ".btn", text: /Next round|New game/, wait: 5
          completed = has_text?("team wins!")
          next if completed

          # Wait for the next round to render before the loop re-reads state.
          click_on "Next round"
          assert_no_button "Next round", wait: 5
        end

        break if completed
      end

      # Red wins 12-8 (a bullseye each of its three active turns).
      game = GameRepo.find(game_id)
      assert_predicate game.status, :completed?
      assert_equal Team.red, game.winner
      assert_equal 12, game.score_for(Team.red)
      assert_equal 8, game.score_for(Team.blue)

      # The win is visible to every session.
      assert_text "Red team wins!", wait: 5
      using_session("ben") { assert_text "Red team wins!", wait: 5 }
      using_session("cleo") { assert_text "Red team wins!", wait: 5 }
      using_session("dana") { assert_text "Red team wins!", wait: 5 }

      # Ada starts a fresh game; teams are retained so it's ready immediately.
      click_on "New game"
      assert_selector "#team_panels", wait: 5
      assert_button "Start game"

      # The reset is broadcast back to the lobby for the others, scores cleared.
      using_session("cleo") do
        assert_selector "#team_panels", wait: 5
        assert_button "Start game"
      end

      reset = GameRepo.find(game_id)
      assert_predicate reset.status, :setup?
      assert_equal 0, reset.score_for(Team.red)
      assert_equal 0, reset.score_for(Team.blue)
    end

    test "validation errors and mid-game joining" do
      # A too-short name is rejected on the create form.
      visit new_wavelength_game_path
      fill_in "Your Name", with: "A"
      click_on "Create New Game"

      assert_text "is too short"
      assert_selector ".invalid-feedback"

      # A valid name creates the game and drops Ada into the lobby.
      fill_in "Your Name", with: "Ada"
      click_on "Create New Game"

      assert_selector "#team_panels"
      game_id = current_path.split("/").last
      within("div.card.border-danger") { click_on "Join" }

      # Ben cannot reuse Ada's name (case-insensitive, emoji-folded).
      using_session("ben") do
        visit new_wavelength_game_player_path(game_id)
        fill_in "Your Name", with: "ada 😀"
        click_on "Join Game"

        assert_text "has already been taken"
        assert_selector ".invalid-feedback"

        fill_in "Your Name", with: "Ben"
        click_on "Join Game"
        within("div.card.border-danger") { click_on "Join" }
      end

      # Only red is staffed (2) — blue still needs players, so no Start button.
      assert_no_button "Start game", wait: 5
      assert_text "Each team needs at least two players"

      # Fill out blue and start.
      using_session("cleo") do
        visit new_wavelength_game_player_path(game_id)
        fill_in "Your Name", with: "Cleo"
        click_on "Join Game"
        within("div.card.border-primary") { click_on "Join" }
      end

      using_session("dana") do
        visit new_wavelength_game_player_path(game_id)
        fill_in "Your Name", with: "Dana"
        click_on "Join Game"
        within("div.card.border-primary") { click_on "Join" }
      end

      assert_button "Start game", wait: 5
      click_on "Start game"
      assert_selector "#play_area", wait: 5

      # Eve joins after kickoff: she has no team yet, so she sees the join gate.
      using_session("eve") do
        visit new_wavelength_game_player_path(game_id)
        fill_in "Your Name", with: "Eve"
        click_on "Join Game"

        assert_button "Join Red", wait: 5
        assert_button "Join Blue"
        click_on "Join Blue"

        # After choosing a side she joins the live game.
        assert_selector "#play_area", wait: 5
      end

      # Eve is now a blue player, surfaced in the live players list for Ada.
      assert_selector "#players #team_blue", text: "Eve", wait: 5
      eve = GameRepo.find(game_id).players.find do |player|
        player.name.to_s == "Eve"
      end
      assert_equal Team.blue, eve.team
    end

    test "players can edit their names with validation and broadcasts" do
      # Ada creates the game; Ben joins so there is someone to broadcast to.
      visit new_wavelength_game_path
      fill_in "Your Name", with: "Ada"
      click_on "Create New Game"

      assert_selector "#team_panels"
      game_id = current_path.split("/").last
      within("div.card.border-danger") { click_on "Join" }

      using_session("ben") do
        visit new_wavelength_game_player_path(game_id)
        fill_in "Your Name", with: "Ben"
        click_on "Join Game"
        within("div.card.border-danger") { click_on "Join" }
      end

      within("div.card.border-danger") { assert_text "Ben", wait: 5 }

      # Ada edits her name with validation failures, then succeeds.
      within "div.card.border-danger" do
        find("a[title='Edit name']").click
      end

      assert_text "Edit your name", wait: 5
      fill_in "Your Name", with: "Ad"
      click_on "Save"
      assert_text "is too short", wait: 5

      fill_in "Your Name", with: "ben 🎉"
      click_on "Save"
      assert_text "has already been taken", wait: 5

      fill_in "Your Name", with: "Alice"
      click_on "Save"
      assert_selector "#team_panels", wait: 5

      # Ben sees Ada's new name in the red panel via broadcast.
      using_session("ben") do
        within "div.card.border-danger" do
          assert_text "Alice", wait: 5
          assert_no_text "Ada"
        end
      end

      # Rename also works during live play (updates the side players list).
      using_session("cleo") do
        visit new_wavelength_game_player_path(game_id)
        fill_in "Your Name", with: "Cleo"
        click_on "Join Game"
        within("div.card.border-primary") { click_on "Join" }
      end

      using_session("dana") do
        visit new_wavelength_game_player_path(game_id)
        fill_in "Your Name", with: "Dana"
        click_on "Join Game"
        within("div.card.border-primary") { click_on "Join" }
      end

      assert_button "Start game", wait: 5
      click_on "Start game"
      assert_selector "#play_area", wait: 5

      using_session("cleo") do
        assert_selector "#players", wait: 5
        within "#players" do
          find("a[title='Edit name']").click
        end
        assert_text "Edit your name", wait: 5
        fill_in "Your Name", with: "Cleopatra"
        click_on "Save"
        assert_selector "#play_area", wait: 5
      end

      # Ada sees Cleo's rename in the live players list via broadcast.
      within "#players" do
        assert_text "Cleopatra", wait: 5
      end
    end

    private

    def session_for(player)
      {
        "Ada" => "default", "Ben" => "ben",
        "Cleo" => "cleo", "Dana" => "dana"
      }.fetch(player.name.to_s)
    end

    def lock_dial(position)
      within "#play_area" do
        find("input[type='range']").set(position)
        click_on "Lock it in"
      end
    end
  end
end
