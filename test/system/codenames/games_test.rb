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

      own_word = game.board.cards.find { |c| c.identity.team == starting }.word
      assassin_word = game.board.cards.find { |c| c.identity.assassin? }.word

      # Bob (active operative) reveals one of his team's agents; turn continues.
      using_session("bob") do
        accept_confirm { find("button", exact_text: own_word).click }
        assert_text "#{starting.to_s.capitalize} team's turn"

        # Then Bob hits the assassin and his team loses.
        accept_confirm { find("button", exact_text: assassin_word).click }
        assert_text "#{starting.opponent.to_s.capitalize} team wins!"
      end

      # Ada sees the loss too, broadcast in real time.
      assert_text "#{starting.opponent.to_s.capitalize} team wins!"
    end
  end
end
