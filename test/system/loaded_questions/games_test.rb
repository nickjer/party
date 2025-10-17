# frozen_string_literal: true

require "application_system_test_case"

module LoadedQuestions
  class GamesTest < ApplicationSystemTestCase
    test "complete game flow with answer swapping" do
      # Create a new game
      visit new_loaded_questions_game_path

      fill_in "Player name", with: "Alice"
      fill_in "Question", with: "What is your favorite color?"
      click_on "Create New Game"

      # Alice should see polling view as the guesser
      assert_text "What is your favorite color?"
      assert_text "Alice"

      # Get the game slug from URL for joining as other players
      game_slug = current_path.split("/").last

      # Open another session as Bob
      using_session("bob") do
        visit new_loaded_questions_game_player_path(game_slug)
        fill_in "Name", with: "Bob"
        click_on "Create New Player"

        # Bob should see the answer form
        assert_text "What is your favorite color?"
        fill_in "player[answer]", with: "Blue"
        click_on "Submit Answer"

        # Wait for answer form to be hidden after submitting
        assert_selector "[data-reveal-target='item'].d-none", visible: :hidden,
          wait: 5
        assert_no_text "Blue"

        # Show answer and verify it was saved
        click_on "Show / Hide Answer"
        assert_text "Blue"
      end

      # Open another session as Charlie
      using_session("charlie") do
        visit new_loaded_questions_game_player_path(game_slug)
        fill_in "Name", with: "Charlie"
        click_on "Create New Player"

        # Charlie should see the answer form
        assert_text "What is your favorite color?"
        fill_in "player[answer]", with: "Red"
        click_on "Submit Answer"

        # Wait for answer form to be hidden after submitting
        assert_selector "[data-reveal-target='item'].d-none", visible: :hidden,
          wait: 5
        assert_no_text "Red"

        # Show answer and verify it was saved
        click_on "Show / Hide Answer"
        assert_text "Red"
      end

      # Back to Alice - she should be able to start matching
      answer1_original = nil
      answer2_original = nil
      using_session("default") do
        # Start the guessing round
        click_on "Begin Guessing"
        within("dialog[open]") do
          click_on "Yes, I am ready"
        end

        # Should see the answers in shuffled order
        assert_text "Blue"
        assert_text "Red"
        assert_text "Bob"
        assert_text "Charlie"

        # Test drag and drop swapping
        swap_items = all(".swap-item")
        assert_equal 2, swap_items.length

        # Remember the original answer assignments (player names stay in
        # same position)
        answer1_original = swap_items[0].text
        answer2_original = swap_items[1].text

        # Drag the first swap item and drop it on the second to swap answers
        swap_items[0].drag_to(swap_items[1])

        # Wait for swap to complete and persist
        sleep 0.5

        # Verify the answers are now swapped visually
        swap_items_after = all(".swap-item")
        assert_equal answer2_original, swap_items_after[0].text,
          "First position should now have second answer"
        assert_equal answer1_original, swap_items_after[1].text,
          "Second position should now have first answer"

        # Refresh the page to verify swap persisted
        visit current_path

        # Verify the swapped order is maintained after refresh
        swap_items_refreshed = all(".swap-item")
        assert_equal answer2_original, swap_items_refreshed[0].text,
          "First position should still have second answer after refresh"
        assert_equal answer1_original, swap_items_refreshed[1].text,
          "Second position should still have first answer after refresh"
      end

      # Verify Bob (non-guesser) sees the swapped order via broadcast
      using_session("bob") do
        # Wait for the broadcast to update Bob's view
        sleep 0.5

        # Bob should see the same swapped order that Alice sees
        guessed_answers = all(".swap-item")
        assert_equal 2, guessed_answers.length
        assert_equal answer2_original, guessed_answers[0].text,
          "Bob should see swapped order - first position"
        assert_equal answer1_original, guessed_answers[1].text,
          "Bob should see swapped order - second position"
      end
    end

    test "complete matching modal interactions" do
      # Create a new game
      visit new_loaded_questions_game_path

      fill_in "Player name", with: "Alice"
      fill_in "Question", with: "What is your favorite color?"
      click_on "Create New Game"

      # Alice should see polling view as the guesser
      assert_text "What is your favorite color?"
      assert_text "Alice"

      # Get the game slug from URL for joining as other players
      game_slug = current_path.split("/").last

      # Open another session as Bob
      using_session("bob") do
        visit new_loaded_questions_game_player_path(game_slug)
        fill_in "Name", with: "Bob"
        click_on "Create New Player"

        # Bob submits answer
        fill_in "player[answer]", with: "Blue"
        click_on "Submit Answer"
      end

      # Open another session as Charlie
      using_session("charlie") do
        visit new_loaded_questions_game_player_path(game_slug)
        fill_in "Name", with: "Charlie"
        click_on "Create New Player"

        # Charlie submits answer
        fill_in "player[answer]", with: "Red"
        click_on "Submit Answer"
      end

      # Back to Alice - start matching phase
      using_session("default") do
        # Start the guessing round
        click_on "Begin Guessing"
        within("dialog[open]") do
          click_on "Yes, I am ready"
        end

        # Should see the Complete Matching button
        assert_button "Complete Matching"

        # Click the Complete Matching button to open modal
        click_on "Complete Matching"

        # Modal should be visible
        assert_selector "dialog[open]", visible: true
        assert_text "Are you sure you would like to finalize your matched " \
          "answers?"

        # Test clicking the X button closes the modal
        find("button.btn-close").click # rubocop:disable Capybara/SpecificActions
        assert_no_selector "dialog[open]", wait: 2
        assert_button "Complete Matching" # Button still visible, page unchanged

        # Open modal again
        click_on "Complete Matching"
        assert_selector "dialog[open]", visible: true

        # Test clicking Close button closes the modal
        within("dialog[open]") do
          click_on "Close"
        end
        assert_no_selector "dialog[open]", wait: 2
        assert_button "Complete Matching" # Button still visible, page unchanged

        # Open modal again and confirm
        click_on "Complete Matching"
        assert_selector "dialog[open]", visible: true

        # Test clicking "Yes, I am sure" makes a request
        within("dialog[open]") do
          click_on "Yes, I am sure"
        end

        # Should redirect to completed view
        assert_no_selector "dialog[open]", wait: 2
        assert_text "Score =", wait: 5
      end
    end

    test "begin guessing modal interactions" do
      # Create a new game
      visit new_loaded_questions_game_path

      fill_in "Player name", with: "Alice"
      fill_in "Question", with: "What is your favorite color?"
      click_on "Create New Game"

      # Alice should see polling view as the guesser
      assert_text "What is your favorite color?"
      assert_text "Alice"

      # Get the game slug from URL for joining as other players
      game_slug = current_path.split("/").last

      # Open another session as Bob
      using_session("bob") do
        visit new_loaded_questions_game_player_path(game_slug)
        fill_in "Name", with: "Bob"
        click_on "Create New Player"

        # Bob submits answer
        fill_in "player[answer]", with: "Blue"
        click_on "Submit Answer"
      end

      # Open another session as Charlie
      using_session("charlie") do
        visit new_loaded_questions_game_player_path(game_slug)
        fill_in "Name", with: "Charlie"
        click_on "Create New Player"

        # Charlie submits answer
        fill_in "player[answer]", with: "Red"
        click_on "Submit Answer"
      end

      # Back to Alice - test Begin Guessing modal
      using_session("default") do
        # Should see the Begin Guessing button
        assert_button "Begin Guessing"

        # Click the Begin Guessing button to open modal
        click_on "Begin Guessing"

        # Modal should be visible
        assert_selector "dialog[open]", visible: true
        assert_text "Are you ready to begin guessing? All answers have been " \
          "submitted."

        # Test clicking the X button closes the modal
        find("button.btn-close").click # rubocop:disable Capybara/SpecificActions
        assert_no_selector "dialog[open]", wait: 2
        assert_button "Begin Guessing" # Button still visible, page unchanged

        # Open modal again
        click_on "Begin Guessing"
        assert_selector "dialog[open]", visible: true

        # Test clicking Close button closes the modal
        within("dialog[open]") do
          click_on "Close"
        end
        assert_no_selector "dialog[open]", wait: 2
        assert_button "Begin Guessing" # Button still visible, page unchanged

        # Open modal again and confirm
        click_on "Begin Guessing"
        assert_selector "dialog[open]", visible: true

        # Test clicking "Yes, I am ready" transitions to guessing phase
        within("dialog[open]") do
          click_on "Yes, I am ready"
        end

        # Should transition to guessing view
        assert_no_selector "dialog[open]", wait: 2
        assert_text "Blue", wait: 5
        assert_text "Red"
        assert_button "Complete Matching"
      end
    end

    test "create next turn hides previous question and shows players" do
      # Create a new game
      visit new_loaded_questions_game_path

      fill_in "Player name", with: "Alice"
      fill_in "Question", with: "What is your favorite color?"
      click_on "Create New Game"

      # Alice should see the question
      assert_text "What is your favorite color?"

      # Get the game slug from URL for joining as other players
      game_slug = current_path.split("/").last

      # Open another session as Bob
      using_session("bob") do
        visit new_loaded_questions_game_player_path(game_slug)
        fill_in "Name", with: "Bob"
        click_on "Create New Player"

        # Bob submits answer
        fill_in "player[answer]", with: "Blue"
        click_on "Submit Answer"
      end

      # Open another session as Charlie
      using_session("charlie") do
        visit new_loaded_questions_game_player_path(game_slug)
        fill_in "Name", with: "Charlie"
        click_on "Create New Player"

        # Charlie submits answer
        fill_in "player[answer]", with: "Red"
        click_on "Submit Answer"
      end

      # Back to Alice - complete the round
      using_session("default") do
        click_on "Begin Guessing"
        within("dialog[open]") do
          click_on "Yes, I am ready"
        end

        # Wait for page transition to complete after modal
        sleep 0.5

        click_on "Complete Matching"
        within("dialog[open]") do
          click_on "Yes, I am sure"
        end

        # Wait for page to load after full reload (turbo: false)
        assert_text "Score =", wait: 10
      end

      # Bob should see the completed page with Create Next Turn link via
      # live updates
      using_session("bob") do
        # Wait for live update to show completed view
        assert_text "Score =", wait: 5
        assert_link "Create Next Turn"

        # Click Create Next Turn
        click_on "Create Next Turn"

        # Should NOT see the previous question
        assert_no_text "What is your favorite color?"

        # Should still see the players
        assert_text "Alice"
        assert_text "Bob"
        assert_text "Charlie"

        # Should see the question field for new round
        assert_field "Question"
      end
    end
  end
end
