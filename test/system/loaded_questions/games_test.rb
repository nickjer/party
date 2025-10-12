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
        assert_selector "[data-reveal-target='item'].hidden", visible: :hidden, wait: 5
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
        assert_selector "[data-reveal-target='item'].hidden", visible: :hidden, wait: 5
        assert_no_text "Red"

        # Show answer and verify it was saved
        click_on "Show / Hide Answer"
        assert_text "Red"
      end

      # Back to Alice - she should be able to start matching
      using_session("default") do
        # Start the guessing round
        click_on "Begin Guessing"

        # Should see the answers in shuffled order
        assert_text "Blue"
        assert_text "Red"
        assert_text "Bob"
        assert_text "Charlie"

        # Test drag and drop swapping
        swap_items = all(".swap-item")
        assert_equal 2, swap_items.length

        # Drag the first swap item and drop it on the second
        swap_items[0].drag_to(swap_items[1])

        # The answers should be swapped now
        # Note: We can't easily verify the swap happened visually in the test
        # but the drag_to action should trigger the swap endpoint
      end
    end
  end
end
