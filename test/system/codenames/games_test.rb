# frozen_string_literal: true

require "application_system_test_case"

module Codenames
  class GamesTest < ApplicationSystemTestCase
    test "teams form in the lobby, play, and win" do
      # Ada creates the game and lands in the lobby.
      visit new_codenames_game_path
      fill_in "Your Name", with: "Ada"
      click_on "Create New Game"

      assert_selector "#team_panels"
      game_id = current_path.split("/").last

      # The first game always starts with the red team.
      # Ada joins the starting team as its spymaster, so she can start.
      within "div.card.border-danger" do
        click_on "Spymaster"
      end
      assert_button "Start game"

      # Bob joins the starting team as an operative.
      using_session("bob") do
        visit new_codenames_game_player_path(game_id)
        fill_in "Your Name", with: "Bob"
        click_on "Join Game"
        within "div.card.border-danger" do
          click_on "Join"
        end
      end

      # Cleo is the opposing spymaster; Dana the opposing operative.
      using_session("cleo") do
        visit new_codenames_game_player_path(game_id)
        fill_in "Your Name", with: "Cleo"
        click_on "Join Game"
        within "div.card.border-primary" do
          click_on "Spymaster"
        end
      end

      using_session("dana") do
        visit new_codenames_game_player_path(game_id)
        fill_in "Your Name", with: "Dana"
        click_on "Join Game"
        within "div.card.border-primary" do
          click_on "Join"
        end
      end

      # Ada starts the game and, as a spymaster, sees the key toggle.
      click_on "Start game"
      assert_button "Show key"

      # Eve joins after the game is underway. She has no team yet, so other
      # players see her online in the "No team" section.
      using_session("eve") do
        visit new_codenames_game_player_path(game_id)
        fill_in "Your Name", with: "Eve"
        click_on "Join Game"
        assert_button "Join Red"
      end

      eve = GameRepo.find(game_id).players.find do |player|
        player.name.to_s == "Eve"
      end
      eve_row = "#player_#{eve.id}"

      within "#players" do
        assert_selector "#{eve_row} i.bi-circle-fill.text-success", wait: 5
        assert_selector "#team_unassigned #{eve_row}"
      end

      # Eve joins the starting team as an operative.
      using_session("eve") do
        click_on "Join Red"
      end

      # Ada sees Eve's row move into the starting team's section in real time.
      assert_selector "#players #team_red #{eve_row}", wait: 5

      board = GameRepo.find(game_id).board
      own_word = board.cards.find { |c| c.identity.team == Team.red }.word
      assassin_word = board.cards.find { |c| c.identity.assassin? }.word

      # Bob cannot reveal until his spymaster posts a clue.
      using_session("bob") do
        assert_text "Spymaster is choosing a clue…"
        assert_no_button own_word
      end

      # Ada, the on-turn spymaster, types the clue for her team. The clue
      # chip uppercases the word for display.
      fill_in "Your clue", with: "Ocean"
      select "∞", from: "Number"
      click_on "Send clue"
      assert_text "OCEAN"
      assert_text "Unlimited guesses"

      # Bob (active operative) reveals one of his team's agents; turn
      # continues. End turn only appears once his team has guessed.
      using_session("bob") do
        assert_text "OCEAN", wait: 5
        assert_no_button "End turn"
        click_button(own_word, exact: true)
        within("dialog[open]") { click_button "Confirm" }
        assert_text "Red team's turn"
        assert_button "End turn"

        # Then Bob hits the assassin and his team loses.
        click_button(assassin_word, exact: true)
        within("dialog[open]") { click_button "Confirm" }
        assert_text "Blue team wins!"
      end

      # Ada sees the loss too, broadcast in real time.
      assert_text "Blue team wins!"
    end
  end
end
