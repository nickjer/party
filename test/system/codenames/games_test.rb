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
      game = GameRepo.new.find(game_id)
      starting = game.starting_team
      start_color = starting.red? ? "danger" : "primary"
      opp_color = starting.red? ? "primary" : "danger"

      # Ada joins the starting team as its spymaster, so she can start.
      within "div.card.border-#{start_color}" do
        click_on "Spymaster"
      end
      assert_button "Start game"

      # Bob joins the starting team as an operative.
      using_session("bob") do
        visit new_codenames_game_player_path(game_id)
        fill_in "Your Name", with: "Bob"
        click_on "Join Game"
        within "div.card.border-#{start_color}" do
          click_on "Join"
        end
      end

      # Cleo is the opposing spymaster; Dana the opposing operative.
      using_session("cleo") do
        visit new_codenames_game_player_path(game_id)
        fill_in "Your Name", with: "Cleo"
        click_on "Join Game"
        within "div.card.border-#{opp_color}" do
          click_on "Spymaster"
        end
      end

      using_session("dana") do
        visit new_codenames_game_player_path(game_id)
        fill_in "Your Name", with: "Dana"
        click_on "Join Game"
        within "div.card.border-#{opp_color}" do
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
        assert_button "Join #{starting.to_s.capitalize}"
      end

      eve = GameRepo.new.find(game_id).players.find do |player|
        player.name.to_s == "Eve"
      end
      eve_row = "#player_#{eve.id}"

      within "#players" do
        assert_selector "#{eve_row} i.bi-circle-fill.text-success", wait: 5
        assert_selector "#team_unassigned #{eve_row}"
      end

      # Eve joins the starting team as an operative.
      using_session("eve") do
        click_on "Join #{starting.to_s.capitalize}"
      end

      # Ada sees Eve's row move into the starting team's section in real time.
      assert_selector "#players #team_#{starting} #{eve_row}", wait: 5

      own_word = game.board.cards.find { |c| c.identity.team == starting }.word
      assassin_word = game.board.cards.find { |c| c.identity.assassin? }.word

      # Bob (active operative) reveals one of his team's agents; turn continues.
      using_session("bob") do
        accept_confirm { click_button(own_word, exact: true) }
        assert_text "#{starting.to_s.capitalize} team's turn"

        # Then Bob hits the assassin and his team loses.
        accept_confirm { click_button(assassin_word, exact: true) }
        assert_text "#{starting.opponent.to_s.capitalize} team wins!"
      end

      # Ada sees the loss too, broadcast in real time.
      assert_text "#{starting.opponent.to_s.capitalize} team wins!"
    end
  end
end
