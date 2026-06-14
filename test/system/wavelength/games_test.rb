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

      # With two per team, only the starting (red) team sees the Start button;
      # blue waits. Whoever on red clicks it becomes the psychic.
      assert_button "Start game", wait: 5
      using_session("cleo") do
        assert_no_button "Start game", wait: 5
        assert_text "Waiting for the Red team to start"
      end

      # Ada (on red) starts the game and so becomes the psychic.
      click_on "Start game"
      assert_selector "#play_area", wait: 5
      assert_text "Red team's turn"

      # ---- Round 1, played out in full with cross-session broadcasts ----
      game = GameRepo.find(game_id) # red starts
      psychic = game.psychic
      guesser = game.guessers.first
      opponent = game.players_on(Team.blue).first
      target = game.target.position

      # The psychic sees the hidden target (shown by default, toggleable) plus
      # a clue input the rest of the table must not see.
      using_session(session_for(psychic)) do
        assert_no_button "Lock it in"
        assert_field "Your clue"
        assert_selector "[data-reveal-target='item']", visible: true
        click_on "Show / hide target"
        assert_no_selector "[data-reveal-target='item']", visible: true
        click_on "Show / hide target"
        assert_selector "[data-reveal-target='item']", visible: true
      end

      # A guesser waits out the clue phase with no clue input and no dial.
      using_session(session_for(guesser)) do
        assert_text "to give a clue", wait: 5
        assert_no_field "Your clue"
        assert_no_button "Send clue"
        assert_no_button "Lock it in"
      end

      # The psychic sends the clue, which opens guessing for the team.
      using_session(session_for(psychic)) do
        fill_in "Your clue", with: "Banana"
        click_on "Send clue"
      end

      # An opponent waits while the red team guesses (no dial controls).
      using_session(session_for(opponent)) do
        assert_text "guessing", wait: 5
        assert_no_button "Lock it in"
        assert_no_button "← Left"
      end

      # The guesser nudges the shared dial; releasing broadcasts the position,
      # and the waiting opponent sees the marker move there in real time.
      using_session(session_for(guesser)) do
        assert_button "Lock it in", wait: 5
        find("#play_area input[type='range']").set(30)
      end
      using_session(session_for(opponent)) do
        within("#wl_dial_marker_#{game_id}") { assert_text "30", wait: 5 }
      end

      # The active guesser locks a near-miss (10 off the target, toward center
      # to stay in range): not a bullseye, so the opponent gets a real
      # left/right call. The active team then waits on that guess.
      locked = target >= 50 ? target - 10 : target + 10
      correct_side = target > locked ? "Right →" : "← Left"
      using_session(session_for(guesser)) do
        assert_button "Lock it in", wait: 5
        lock_dial(locked)
        assert_text "Waiting", wait: 5 # active team now waits on the opponent
      end

      # While the opponent decides, the psychic sees the target and the locked
      # guess's score (two reveal items); the toggle hides both at once.
      using_session(session_for(psychic)) do
        assert_text "Waiting", wait: 5
        assert_selector "[data-reveal-target='item']", visible: true, minimum: 2
        click_on "Show / hide target"
        assert_no_selector "[data-reveal-target='item']", visible: true
      end

      # The opponent now sees the left/right catch-up via broadcast and nails
      # the correct side.
      using_session(session_for(opponent)) do
        assert_text "Is the target left or right", wait: 5
        click_on correct_side
        # Wait for the reveal before reading state (the PATCH is async).
        assert_button "Next round", wait: 5
      end

      # The near-miss scores 2 for red; blue's correct side steals 1 on top of
      # its 1-point head start (the team that goes second).
      assert_equal 2, GameRepo.find(game_id).score_for(Team.red)
      assert_equal 2, GameRepo.find(game_id).score_for(Team.blue)

      # On the reveal, only the up (blue) team can continue; the red psychic
      # who just played waits while blue picks the next psychic (broadcast).
      using_session(session_for(psychic)) do
        assert_no_button "Next round", wait: 5
        assert_text "Waiting for the Blue team to pick a psychic"
      end
      using_session(session_for(opponent)) do
        click_on "Next round"
      end

      # The turn passes to blue, and the opponent who continued is its psychic.
      using_session(session_for(guesser)) do
        assert_text "Blue team's turn", wait: 5
      end
      next_round = GameRepo.find(game_id)
      assert_equal Team.blue, next_round.current_team
      assert_equal opponent.id, next_round.psychic.id

      # ---- Drive the remaining rounds with bullseyes until a team wins ----
      loop do
        game = GameRepo.find(game_id)
        break if game.status.completed?

        psychic = game.psychic
        guesser = game.guessers.first
        up_player = game.players_on(game.current_team.opponent).first
        target = game.target.position

        # Each round opens in the clue phase: the psychic sends a clue before
        # the team can move the dial.
        using_session(session_for(psychic)) do
          assert_button "Send clue", wait: 5
          fill_in "Your clue", with: "Banana"
          click_on "Send clue"
        end

        using_session(session_for(guesser)) do
          assert_button "Lock it in", wait: 5
          lock_dial(target) # dead-on bullseye: the opponent gets no guess
          # The lock resolves to a reveal ("Waiting") or, on the final turn,
          # the win banner.
          assert_text(/Waiting|wins!/, wait: 5)
        end

        # A bullseye settles the round outright, so the up team never sees the
        # left/right step — they land straight on the reveal (or win banner).
        completed = false
        using_session(session_for(up_player)) do
          assert_selector ".btn", text: /Next round|New game/, wait: 5
          assert_no_text "Is the target left or right"
          completed = has_text?("team wins!")
          next if completed

          # Wait for the next round to render before the loop re-reads state.
          click_on "Next round"
          assert_no_button "Next round", wait: 5
        end

        break if completed
      end

      # Blue wins 10-6: its 1-point head start, the round-1 steal (1), and two
      # bullseyes (4 + 4); red managed its round-1 near-miss (2) plus one
      # bullseye (4) before blue closed it out.
      game = GameRepo.find(game_id)
      assert_predicate game.status, :completed?
      assert_equal Team.blue, game.winner
      assert_equal 6, game.score_for(Team.red)
      assert_equal 10, game.score_for(Team.blue)

      # The win is visible to every session.
      assert_text "Blue team wins!", wait: 5
      using_session("ben") { assert_text "Blue team wins!", wait: 5 }
      using_session("cleo") { assert_text "Blue team wins!", wait: 5 }
      using_session("dana") { assert_text "Blue team wins!", wait: 5 }

      # Ada starts a fresh game; teams are retained so it's ready immediately.
      # The starting team flips to blue, so blue now owns the Start button.
      click_on "New game"
      assert_selector "#team_panels", wait: 5
      assert_no_button "Start game" # Ada is on red; blue starts now
      assert_text "Waiting for the Blue team to start"

      # The reset is broadcast back to the lobby; blue (Cleo) can start.
      using_session("cleo") do
        assert_selector "#team_panels", wait: 5
        assert_button "Start game", wait: 5
      end

      reset = GameRepo.find(game_id)
      assert_predicate reset.status, :setup?
      assert_equal 0, reset.score_for(Team.blue) # new starting team
      assert_equal 1, reset.score_for(Team.red)  # second team's head start
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

      assert_text "Edit Your Name", wait: 5

      # Cancel returns to the lobby without changing the name
      click_on "Cancel"
      assert_selector "#team_panels", wait: 5
      assert_no_text "Edit Your Name"
      within("div.card.border-danger") { assert_text "Ada" }

      # Reopen the edit form to continue
      within "div.card.border-danger" do
        find("a[title='Edit name']").click
      end
      assert_text "Edit Your Name", wait: 5

      fill_in "Your Name", with: "Ad"
      click_on "Update Name"
      assert_text "is too short", wait: 5

      fill_in "Your Name", with: "ben 🎉"
      click_on "Update Name"
      assert_text "has already been taken", wait: 5

      fill_in "Your Name", with: "Alice"
      click_on "Update Name"
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
        assert_text "Edit Your Name", wait: 5
        fill_in "Your Name", with: "Cleopatra"
        click_on "Update Name"
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
