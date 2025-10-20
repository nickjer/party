# frozen_string_literal: true

require "application_system_test_case"

module LoadedQuestions
  class GamesTest < ApplicationSystemTestCase
    test "complete game flow with answer swapping" do
      # Create a new game with Mia as guesser (middle alphabetically)
      visit new_loaded_questions_game_path

      fill_in "Your Name", with: "Mia"
      fill_in "First Question", with: "What is your favorite color?"
      click_on "Create New Game"

      # Mia should see polling view as the guesser
      assert_text "What is your favorite color?"
      assert_text "Mia"

      # Get the game slug from URL for joining as other players
      game_slug = current_path.split("/").last

      # Verify initial player list for Mia (only she exists at this point)
      using_session("default") do
        within("#players") do
          player_divs = all("div[id^='player_']")
          assert_equal 1, player_divs.length

          # Mia should have star (guesser) and bold name (current player)
          within(player_divs[0]) do
            assert_selector "i.bi-star-fill", count: 1
            assert_selector "span.fw-bold", text: "Mia"
          end
        end
      end

      # Zoe joins second (higher alphabetically - will display last)
      using_session("zoe") do
        visit new_loaded_questions_game_player_path(game_slug)
        fill_in "Name", with: "Zoe"
        click_on "Join Game"

        # Zoe should see the answer form
        assert_text "What is your favorite color?"
        assert_field "player[answer]"

        # Zoe should NOT see Begin Guessing button (not the guesser)
        assert_no_button "Begin Guessing"

        # Verify Zoe sees alphabetized player list: Mia, Zoe
        within("#players") do
          player_divs = all("div[id^='player_']")
          assert_equal 2, player_divs.length

          # First should be Mia (guesser)
          within(player_divs[0]) do
            assert_selector "i.bi-star-fill", count: 1 # Star (guesser)
            # Not current player
            assert_selector "span:not(.fw-bold)", text: "Mia"
          end

          # Second should be Zoe
          within(player_divs[1]) do
            assert_selector "i.bi-square", count: 1 # Empty box (not answered)
            assert_selector "span.fw-bold", text: "Zoe" # Current player
          end
        end
      end

      # Verify Mia sees the updated alphabetized list
      using_session("default") do
        within("#players") do
          player_divs = all("div[id^='player_']", wait: 5)
          assert_equal 2, player_divs.length

          # First should be Mia (current player)
          within(player_divs[0]) do
            assert_selector "i.bi-star-fill", count: 1
            assert_selector "span.fw-bold", text: "Mia"
          end

          # Second should be Zoe
          within(player_divs[1]) do
            assert_selector "i.bi-square", count: 1
            assert_selector "span:not(.fw-bold)", text: "Zoe"
          end
        end
      end

      # Alice joins third (lower alphabetically - will display first)
      using_session("alice") do
        visit new_loaded_questions_game_player_path(game_slug)
        fill_in "Name", with: "Alice"
        click_on "Join Game"

        # Alice should see the answer form
        assert_text "What is your favorite color?"
        assert_field "player[answer]"

        # Alice should NOT see Begin Guessing button (not the guesser)
        assert_no_button "Begin Guessing"

        # Verify Alice sees alphabetized player list: Alice, Mia, Zoe
        within("#players") do
          player_divs = all("div[id^='player_']")
          assert_equal 3, player_divs.length

          within(player_divs[0]) do
            assert_selector "i.bi-square", count: 1
            assert_selector "span.fw-bold", text: "Alice" # Current player
          end

          within(player_divs[1]) do
            assert_selector "i.bi-star-fill", count: 1
            assert_selector "span:not(.fw-bold)", text: "Mia"
          end

          within(player_divs[2]) do
            assert_selector "i.bi-square", count: 1
            assert_selector "span:not(.fw-bold)", text: "Zoe"
          end
        end
      end

      # Verify all sessions see the same alphabetized order: Alice, Mia, Zoe
      using_session("default") do
        within("#players") do
          player_divs = all("div[id^='player_']", wait: 5)
          assert_equal 3, player_divs.length

          within(player_divs[0]) do
            assert_selector "i.bi-square", count: 1
            assert_selector "span:not(.fw-bold)", text: "Alice"
          end

          within(player_divs[1]) do
            assert_selector "i.bi-star-fill", count: 1
            assert_selector "span.fw-bold", text: "Mia"
          end

          within(player_divs[2]) do
            assert_selector "i.bi-square", count: 1
            assert_selector "span:not(.fw-bold)", text: "Zoe"
          end
        end
      end

      using_session("zoe") do
        within("#players") do
          player_divs = all("div[id^='player_']", wait: 5)
          assert_equal 3, player_divs.length

          within(player_divs[0]) do
            assert_selector "i.bi-square", count: 1
            assert_selector "span:not(.fw-bold)", text: "Alice"
          end

          within(player_divs[1]) do
            assert_selector "i.bi-star-fill", count: 1
            assert_selector "span:not(.fw-bold)", text: "Mia"
          end

          within(player_divs[2]) do
            assert_selector "i.bi-square", count: 1
            assert_selector "span.fw-bold", text: "Zoe"
          end
        end
      end

      # Alice submits an answer
      using_session("alice") do
        fill_in "player[answer]", with: "Blue"
        click_on "Submit Answer"

        # Wait for answer form to be hidden after submitting
        assert_selector "[data-reveal-target='item'].d-none", visible: :hidden,
          wait: 5
        assert_no_text "Blue"

        # Show answer and verify it was saved
        click_on "Show / Hide Answer"
        assert_text "Blue"

        # Verify Alice now has a checkmark in her own view
        within("#players") do
          player_divs = all("div[id^='player_']")
          within(player_divs[0]) do
            assert_selector "i.bi-check-square-fill", count: 1 # Checkmark
            assert_selector "span.fw-bold", text: "Alice"
          end
        end
      end

      # Verify all sessions see Alice's checkmark
      using_session("default") do
        within("#players") do
          player_divs = all("div[id^='player_']", wait: 5)
          within(player_divs[0]) do
            assert_selector "i.bi-check-square-fill", count: 1
            assert_selector "span:not(.fw-bold)", text: "Alice"
          end
        end
      end

      using_session("zoe") do
        within("#players") do
          player_divs = all("div[id^='player_']", wait: 5)
          within(player_divs[0]) do
            assert_selector "i.bi-check-square-fill", count: 1
            assert_selector "span:not(.fw-bold)", text: "Alice"
          end
        end
      end

      # Zoe submits an answer
      using_session("zoe") do
        fill_in "player[answer]", with: "Red"
        click_on "Submit Answer"

        # Wait for answer form to be hidden after submitting
        assert_selector "[data-reveal-target='item'].d-none", visible: :hidden,
          wait: 5
        assert_no_text "Red"

        # Show answer and verify it was saved
        click_on "Show / Hide Answer"
        assert_text "Red"

        # Verify Zoe now has a checkmark in her own view
        within("#players") do
          player_divs = all("div[id^='player_']")
          within(player_divs[2]) do
            assert_selector "i.bi-check-square-fill", count: 1
            assert_selector "span.fw-bold", text: "Zoe"
          end
        end
      end

      # Verify all sessions see both checkmarks
      using_session("default") do
        within("#players") do
          player_divs = all("div[id^='player_']", wait: 5)
          within(player_divs[0]) do
            assert_selector "i.bi-check-square-fill", count: 1
            assert_selector "span:not(.fw-bold)", text: "Alice"
          end
          within(player_divs[2]) do
            assert_selector "i.bi-check-square-fill", count: 1
            assert_selector "span:not(.fw-bold)", text: "Zoe"
          end
        end
      end

      using_session("alice") do
        within("#players") do
          player_divs = all("div[id^='player_']", wait: 5)
          within(player_divs[2]) do
            assert_selector "i.bi-check-square-fill", count: 1
            assert_selector "span:not(.fw-bold)", text: "Zoe"
          end
        end
      end

      # Back to Mia - she should be able to start matching
      answer1_original = nil
      answer2_original = nil
      using_session("default") do
        # Mia (guesser) should see Begin Guessing button
        assert_button "Begin Guessing"

        # Start the guessing round
        click_on "Begin Guessing"
        within("dialog[open]") do
          click_on "Yes, I am ready"
        end

        # Should see the answers in shuffled order
        assert_text "Blue"
        assert_text "Red"
        assert_text "Alice"
        assert_text "Zoe"

        # Mia (guesser) should see Complete Matching button
        assert_button "Complete Matching"

        # Test drag and drop swapping
        swap_items = all(".swap-item")
        assert_equal 2, swap_items.length

        # Remember the original answer assignments
        answer1_original = swap_items[0].text
        answer2_original = swap_items[1].text

        # Always swap at least once to test the swap functionality
        swap_items[0].drag_to(swap_items[1])

        # Wait for swap to complete and persist
        sleep 0.5

        # Verify the answers are now swapped visually
        swap_items_after = all(".swap-item")
        assert_equal answer2_original, swap_items_after[0].text
        assert_equal answer1_original, swap_items_after[1].text

        # Refresh the page to verify swap persisted
        visit current_path

        # Verify the swapped order is maintained after refresh
        swap_items_refreshed = all(".swap-item")
        assert_equal answer2_original, swap_items_refreshed[0].text
        assert_equal answer1_original, swap_items_refreshed[1].text
      end

      # Verify Alice (non-guesser) sees the swapped order via broadcast
      using_session("alice") do
        # Wait for the broadcast to update Alice's view
        sleep 0.5

        # Alice should see the same swapped order that Mia sees
        guessed_answers = all(".swap-item")
        assert_equal 2, guessed_answers.length
        assert_equal answer2_original, guessed_answers[0].text
        assert_equal answer1_original, guessed_answers[1].text

        # Alice should NOT see Complete Matching button (not the guesser)
        assert_no_button "Complete Matching"
      end

      # Verify Zoe (non-guesser) sees the swapped order via broadcast
      using_session("zoe") do
        # Wait for the broadcast to update Zoe's view
        sleep 0.5

        # Zoe should see the same swapped order
        guessed_answers = all(".swap-item")
        assert_equal 2, guessed_answers.length
        assert_equal answer2_original, guessed_answers[0].text
        assert_equal answer1_original, guessed_answers[1].text

        # Zoe should NOT see Complete Matching button (not the guesser)
        assert_no_button "Complete Matching"
      end

      # Back to Mia - swap again if needed to get correct matches
      using_session("default") do
        swap_items_current = all(".swap-item")

        # Players are alphabetically sorted: Alice (index 0), Zoe (index 1)
        # Alice should match with Blue, Zoe should match with Red
        answer1 = swap_items_current[0].text
        needs_second_swap = answer1 != "Blue"

        if needs_second_swap
          # Swap again to get correct matches
          swap_items_current[0].drag_to(swap_items_current[1])
          sleep 0.5
        end

        # Verify correct matches (Alice->Blue, Zoe->Red)
        swap_items_final = all(".swap-item")
        assert_equal "Blue", swap_items_final[0].text
        assert_equal "Red", swap_items_final[1].text
      end

      # Complete the matching round
      using_session("default") do
        click_on "Complete Matching"
        within("dialog[open]") do
          click_on "Yes, I am sure"
        end

        # Wait for completed view to load
        assert_text "Score:", wait: 10

        # Mia (guesser) should NOT see "Create Next Turn" button
        assert_no_link "Create Next Turn"
      end

      # Verify all three sessions see the completed view with same results
      using_session("default") do
        # Wait for page to fully load
        assert_text "Mia's Score:", wait: 5

        # Store Mia's view for comparison
        assert_text "Alice"
        assert_text "Zoe"
        assert_text "Blue"
        assert_text "Red"

        # Extract the score from the card
        mia_score_text = find(".card-footer", text: /Score:/).text
        assert_match(%r{Mia's Score:\s+2 / 2}, mia_score_text)

        # Verify Mia's score badge in player list shows 2
        within("#players") do
          mia_div = find("div[id^='player_']", text: "Mia")
          within(mia_div) do
            assert_selector ".badge", text: "2"
          end
        end

        # Mia (guesser) should NOT see "Create Next Turn" button
        assert_no_link "Create Next Turn"
      end

      using_session("alice") do
        # Wait for broadcast to show completed view
        assert_text "Mia's Score:", wait: 5

        # Alice should see the same content
        assert_text "Alice"
        assert_text "Zoe"
        assert_text "Blue"
        assert_text "Red"

        # Should see "Create Next Turn" button (non-guesser)
        assert_link "Create Next Turn"

        # Extract Alice's score text
        alice_score_text = find(".card-footer", text: /Score:/).text
        assert_match(%r{Mia's Score:\s+2 / 2}, alice_score_text)

        # Verify Alice sees Mia's score badge as 2 in player list
        within("#players") do
          mia_div = find("div[id^='player_']", text: "Mia")
          within(mia_div) do
            assert_selector ".badge", text: "2"
          end
        end
      end

      using_session("zoe") do
        # Wait for broadcast to show completed view
        assert_text "Mia's Score:", wait: 5

        # Zoe should see the same content
        assert_text "Alice"
        assert_text "Zoe"
        assert_text "Blue"
        assert_text "Red"

        # Should see "Create Next Turn" button (non-guesser)
        assert_link "Create Next Turn"

        # Extract Zoe's score text
        zoe_score_text = find(".card-footer", text: /Score:/).text
        assert_match(%r{Mia's Score:\s+2 / 2}, zoe_score_text)

        # Verify Zoe sees Mia's score badge as 2 in player list
        within("#players") do
          mia_div = find("div[id^='player_']", text: "Mia")
          within(mia_div) do
            assert_selector ".badge", text: "2"
          end
        end
      end

      # Alice creates a new round and becomes the guesser
      using_session("alice") do
        click_on "Create Next Turn"

        # Should see the new round form
        assert_field "Your Question"

        # Fill in new question
        fill_in "Your Question", with: "What is your dream vacation?"
        click_on "Create Next Turn"

        # Wait for new round to start
        assert_text "What is your dream vacation?", wait: 5

        # Alice should now be the guesser and see Begin Guessing button
        assert_button "Begin Guessing"

        # Alice should NOT see an answer form (she's the guesser)
        assert_no_field "player[answer]"

        # Verify player list: Alice (star), Mia (box), Zoe (box)
        within("#players") do
          player_divs = all("div[id^='player_']")
          assert_equal 3, player_divs.length

          # Alice should have star (guesser) and be bold (current player)
          within(player_divs[0]) do
            assert_selector "i.bi-star-fill", count: 1
            assert_selector "span.fw-bold", text: "Alice"
          end

          # Mia should have empty box (not answered)
          within(player_divs[1]) do
            assert_selector "i.bi-square", count: 1
            assert_selector "span:not(.fw-bold)", text: "Mia"
          end

          # Zoe should have empty box (not answered)
          within(player_divs[2]) do
            assert_selector "i.bi-square", count: 1
            assert_selector "span:not(.fw-bold)", text: "Zoe"
          end
        end
      end

      # Verify Mia sees the new round via broadcast
      using_session("default") do
        # Should see new question
        assert_text "What is your dream vacation?", wait: 5

        # Mia should now see the answer form (she's no longer the guesser)
        assert_field "player[answer]"

        # Answer field should be empty
        assert_equal "", find_field("player[answer]").value

        # Should NOT see Begin Guessing button (not the guesser)
        assert_no_button "Begin Guessing"

        # Verify player list shows Alice as guesser
        within("#players") do
          player_divs = all("div[id^='player_']")
          assert_equal 3, player_divs.length

          # Alice should have star (guesser), not bold (not current player)
          within(player_divs[0]) do
            assert_selector "i.bi-star-fill", count: 1
            assert_selector "span:not(.fw-bold)", text: "Alice"
          end

          # Mia should have empty box and be bold (current player)
          within(player_divs[1]) do
            assert_selector "i.bi-square", count: 1
            assert_selector "span.fw-bold", text: "Mia"
          end

          # Zoe should have empty box
          within(player_divs[2]) do
            assert_selector "i.bi-square", count: 1
            assert_selector "span:not(.fw-bold)", text: "Zoe"
          end
        end
      end

      # Verify Zoe sees the new round via broadcast
      using_session("zoe") do
        # Should see new question
        assert_text "What is your dream vacation?", wait: 5

        # Zoe should now see the answer form (she's not the guesser)
        assert_field "player[answer]"

        # Answer field should be empty
        assert_equal "", find_field("player[answer]").value

        # Should NOT see Begin Guessing button (not the guesser)
        assert_no_button "Begin Guessing"

        # Verify player list shows Alice as guesser
        within("#players") do
          player_divs = all("div[id^='player_']")
          assert_equal 3, player_divs.length

          # Alice should have star (guesser)
          within(player_divs[0]) do
            assert_selector "i.bi-star-fill", count: 1
            assert_selector "span:not(.fw-bold)", text: "Alice"
          end

          # Mia should have empty box
          within(player_divs[1]) do
            assert_selector "i.bi-square", count: 1
            assert_selector "span:not(.fw-bold)", text: "Mia"
          end

          # Zoe should have empty box and be bold (current player)
          within(player_divs[2]) do
            assert_selector "i.bi-square", count: 1
            assert_selector "span.fw-bold", text: "Zoe"
          end
        end
      end
    end

    test "validation errors and edge cases" do
      # Try to create a game with invalid inputs (too short)
      visit new_loaded_questions_game_path

      fill_in "Your Name", with: "A"
      fill_in "First Question", with: "Q"
      click_on "Create New Game"

      # Should see validation errors under the inputs
      assert_text "is too short", count: 2
      assert_selector ".invalid-feedback", count: 2

      # Create game successfully with valid inputs
      fill_in "Your Name", with: "Alice"
      fill_in "First Question", with: "What is your favorite movie?"
      click_on "Create New Game"

      # Should see the game view
      assert_text "What is your favorite movie?"
      assert_text "Alice"

      game_slug = current_path.split("/").last

      # Try to join with a name that's the same but with emoji
      using_session("bob") do
        visit new_loaded_questions_game_player_path(game_slug)
        fill_in "Name", with: "Alice 😀"
        click_on "Join Game"

        # Should see validation error about duplicate name
        assert_text "has already been taken"
        assert_selector ".invalid-feedback", count: 1

        # Join with a valid unique name
        fill_in "Name", with: "Bob"
        click_on "Join Game"

        # Should see the answer form
        assert_text "What is your favorite movie?"
        assert_field "player[answer]"

        # Submit an answer
        fill_in "player[answer]", with: "The Matrix"
        click_on "Submit Answer"

        # Wait for answer form to be hidden
        assert_selector "[data-reveal-target='item'].d-none", visible: :hidden,
          wait: 5
      end

      # Back to Alice - try to begin matching with only 1 answer
      using_session("default") do
        # Should see Begin Guessing button
        assert_button "Begin Guessing"

        # Open the modal
        click_on "Begin Guessing"
        assert_selector "dialog[open]", visible: true

        # Try to submit with insufficient answers
        within("dialog[open]") do
          click_on "Yes, I am ready"
        end

        # Should see error message about needing more answers
        assert_selector ".alert-danger", wait: 5
        assert_text "Not enough players have answered (need at least 2)"

        # Modal should be closed
        assert_no_selector "dialog[open]"

        # Should still be on polling view with Begin Guessing button
        assert_button "Begin Guessing"
      end

      # Have Charlie join and answer
      using_session("charlie") do
        visit new_loaded_questions_game_player_path(game_slug)
        fill_in "Name", with: "Charlie"
        click_on "Join Game"

        # Should see the answer form
        assert_text "What is your favorite movie?"
        assert_field "player[answer]"

        # Verify Charlie sees empty box next to his own name
        within("#players") do
          # Find Charlie's player div (alphabetically: Alice, Bob, Charlie)
          player_divs = all("div[id^='player_']")
          within(player_divs[2]) do
            assert_selector "i.bi-square", count: 1 # Empty box
            assert_selector "span.fw-bold", text: "Charlie" # Current player
          end
        end

        # Try to submit 1-letter answer
        fill_in "player[answer]", with: "I"
        click_on "Submit Answer"

        # Should see validation error
        assert_text "is too short"
        assert_selector ".invalid-feedback", count: 1

        # Answer form should still be visible
        assert_field "player[answer]"

        # Charlie should still have empty box
        within("#players") do
          player_divs = all("div[id^='player_']")
          within(player_divs[2]) do
            assert_selector "i.bi-square", count: 1
          end
        end
      end

      # Verify Alice sees Charlie with empty box
      using_session("default") do
        within("#players") do
          player_divs = all("div[id^='player_']", wait: 5)
          # Charlie should be third: Alice (box), Bob (check), Charlie (box)
          within(player_divs[2]) do
            assert_selector "i.bi-square", count: 1
            assert_selector "span:not(.fw-bold)", text: "Charlie"
          end
        end
      end

      # Verify Bob sees Charlie with empty box
      using_session("bob") do
        within("#players") do
          player_divs = all("div[id^='player_']", wait: 5)
          within(player_divs[2]) do
            assert_selector "i.bi-square", count: 1
            assert_selector "span:not(.fw-bold)", text: "Charlie"
          end
        end
      end

      # Charlie submits a proper answer
      using_session("charlie") do
        fill_in "player[answer]", with: "Inception"
        click_on "Submit Answer"

        # Wait for answer to be submitted
        assert_selector "[data-reveal-target='item'].d-none", visible: :hidden,
          wait: 5

        # Charlie should now have checkmark
        within("#players") do
          player_divs = all("div[id^='player_']")
          within(player_divs[2]) do
            assert_selector "i.bi-check-square-fill", count: 1
            assert_selector "span.fw-bold", text: "Charlie"
          end
        end
      end

      # Verify Alice sees Charlie with checkmark
      using_session("default") do
        within("#players") do
          player_divs = all("div[id^='player_']", wait: 5)
          within(player_divs[2]) do
            assert_selector "i.bi-check-square-fill", count: 1
            assert_selector "span:not(.fw-bold)", text: "Charlie"
          end
        end
      end

      # Verify Bob sees Charlie with checkmark
      using_session("bob") do
        within("#players") do
          player_divs = all("div[id^='player_']", wait: 5)
          within(player_divs[2]) do
            assert_selector "i.bi-check-square-fill", count: 1
            assert_selector "span:not(.fw-bold)", text: "Charlie"
          end
        end
      end

      # Back to Alice - test modal cancel behaviors
      using_session("default") do
        # Wait for Charlie's answer to be broadcast
        within("#players") do
          assert_selector "i.bi-check-square-fill", count: 2, wait: 5
        end

        # Open the Begin Guessing modal
        click_on "Begin Guessing"

        # Modal should be visible
        assert_selector "dialog[open]", visible: true
        assert_text "Are you ready to begin guessing?"

        # Click the X button to close
        find("button.btn-close").click # rubocop:disable Capybara/SpecificActions
        assert_no_selector "dialog[open]", wait: 2

        # Should still be on polling view
        assert_button "Begin Guessing"

        # Open modal again
        click_on "Begin Guessing"
        assert_selector "dialog[open]", visible: true

        # Click the Close button
        within("dialog[open]") do
          click_on "Close"
        end
        assert_no_selector "dialog[open]", wait: 2

        # Should still be on polling view
        assert_button "Begin Guessing"

        # Open modal again and confirm this time
        click_on "Begin Guessing"
        within("dialog[open]") do
          click_on "Yes, I am ready"
        end

        # Should transition to guessing view
        assert_no_selector "dialog[open]", wait: 2
        assert_text "The Matrix", wait: 5
        assert_text "Inception"
        assert_button "Complete Matching"

        # Test Complete Matching modal cancel behaviors
        click_on "Complete Matching"

        # Modal should be visible
        assert_selector "dialog[open]", visible: true
        assert_text "Are you sure you would like to finalize your matched " \
          "answers?"

        # Click the X button to close
        find("button.btn-close").click # rubocop:disable Capybara/SpecificActions
        assert_no_selector "dialog[open]", wait: 2

        # Should still be on guessing view
        assert_button "Complete Matching"

        # Open modal again
        click_on "Complete Matching"
        assert_selector "dialog[open]", visible: true

        # Click the Close button
        within("dialog[open]") do
          click_on "Close"
        end
        assert_no_selector "dialog[open]", wait: 2

        # Should still be on guessing view
        assert_button "Complete Matching"

        # Open modal again and confirm this time
        click_on "Complete Matching"
        within("dialog[open]") do
          click_on "Yes, I am sure"
        end

        # Should transition to completed view
        assert_no_selector "dialog[open]", wait: 2
        assert_text "Alice's Score:", wait: 5

        # Alice should NOT see Create Next Turn button (guesser)
        assert_no_link "Create Next Turn"
      end

      # Bob tries to create a new turn with invalid question
      using_session("bob") do
        # Wait for broadcast to show completed view
        assert_text "Alice's Score:", wait: 5

        # Bob should see Create Next Turn button (non-guesser)
        assert_link "Create Next Turn"

        # Click to create new turn
        click_on "Create Next Turn"

        # Should see the new round form
        assert_field "Your Question"

        # Try to submit with 1-letter question
        fill_in "Your Question", with: "Q"
        click_on "Create Next Turn"

        # Should see validation error
        assert_text "is too short"
        assert_selector ".invalid-feedback", count: 1

        # Fill in valid question
        fill_in "Your Question", with: "What is your favorite book?"
        click_on "Create Next Turn"

        # Should see the new question
        assert_text "What is your favorite book?", wait: 5

        # Bob should now be the guesser
        assert_button "Begin Guessing"
        assert_no_field "player[answer]"
      end

      # Verify Alice sees the new round via broadcast
      using_session("default") do
        # Should see new question
        assert_text "What is your favorite book?", wait: 5

        # Alice should now see the answer form (no longer guesser)
        assert_field "player[answer]"
        assert_no_button "Begin Guessing"
      end

      # Verify Charlie sees the new round via broadcast
      using_session("charlie") do
        # Should see new question
        assert_text "What is your favorite book?", wait: 5

        # Charlie should see the answer form
        assert_field "player[answer]"
        assert_no_button "Begin Guessing"
      end
    end

    test "players can edit their names with validation and broadcasts" do
      # Create a new game with Bob as guesser
      visit new_loaded_questions_game_path

      fill_in "Your Name", with: "Bob"
      fill_in "First Question", with: "What is your favorite color?"
      click_on "Create New Game"

      assert_text "Bob"
      game_slug = current_path.split("/").last

      # Charlie joins the game
      using_session("charlie") do
        visit new_loaded_questions_game_player_path(game_slug)
        fill_in "Name", with: "Charlie"
        click_on "Join Game"
        assert_text "Charlie"
      end

      # Zoe joins the game
      using_session("zoe") do
        visit new_loaded_questions_game_player_path(game_slug)
        fill_in "Name", with: "Zoe"
        click_on "Join Game"
        assert_text "Zoe"
      end

      # Charlie clicks the edit button
      using_session("charlie") do
        within("#players") do
          # Find Charlie's player div and click the edit button
          charlie_div = find("div[id^='player_']", text: "Charlie")
          within(charlie_div) do
            find("a[title='Edit name']").click
          end
        end

        # Should see the edit form
        assert_text "Edit Your Name", wait: 5
        assert_field "Your Name", with: "Charlie"

        # Try to change name to something too short
        fill_in "Your Name", with: "Ch"
        click_on "Update Name"

        # Should see validation error
        assert_text "is too short", wait: 5
        assert_field "Your Name", with: "Ch"

        # Try to change name to match Bob (case insensitive with emoji)
        fill_in "Your Name", with: "bob 🎉"
        click_on "Update Name"

        # Should see validation error
        assert_text "has already been taken", wait: 5
        assert_field "Your Name", with: "bob 🎉"

        # Change name successfully to Alice (sorts to beginning)
        fill_in "Your Name", with: "Alice"
        click_on "Update Name"

        # Should be redirected back to game
        assert_text "What is your favorite color?", wait: 5
        assert_no_text "Edit Your Name"

        # Verify player list is updated and sorted: Alice, Bob, Zoe
        within("#players") do
          player_divs = all("div[id^='player_']")
          assert_equal 3, player_divs.length

          within(player_divs[0]) do
            assert_selector "span.fw-bold", text: "Alice"
          end

          within(player_divs[1]) do
            assert_selector "span:not(.fw-bold)", text: "Bob"
          end

          within(player_divs[2]) do
            assert_selector "span:not(.fw-bold)", text: "Zoe"
          end
        end
      end

      # Verify Bob sees the updated player list via broadcast
      using_session("default") do
        within("#players", wait: 5) do
          player_divs = all("div[id^='player_']")
          assert_equal 3, player_divs.length

          within(player_divs[0]) do
            assert_selector "span:not(.fw-bold)", text: "Alice"
          end

          within(player_divs[1]) do
            assert_selector "span.fw-bold", text: "Bob"
          end

          within(player_divs[2]) do
            assert_selector "span:not(.fw-bold)", text: "Zoe"
          end
        end
      end

      # Verify Zoe sees the updated player list via broadcast
      using_session("zoe") do
        within("#players", wait: 5) do
          player_divs = all("div[id^='player_']")
          assert_equal 3, player_divs.length

          within(player_divs[0]) do
            assert_selector "span:not(.fw-bold)", text: "Alice"
          end

          within(player_divs[1]) do
            assert_selector "span:not(.fw-bold)", text: "Bob"
          end

          within(player_divs[2]) do
            assert_selector "span.fw-bold", text: "Zoe"
          end
        end
      end

      # Now Zoe changes her name to Mia (sorts to middle)
      using_session("zoe") do
        within("#players") do
          zoe_div = find("div[id^='player_']", text: "Zoe")
          within(zoe_div) do
            find("a[title='Edit name']").click
          end
        end

        assert_text "Edit Your Name", wait: 5
        fill_in "Your Name", with: "Mia"
        click_on "Update Name"

        # Should be redirected back to game
        assert_text "What is your favorite color?", wait: 5

        # Verify player list is updated and sorted: Alice, Bob, Mia
        within("#players") do
          player_divs = all("div[id^='player_']")
          assert_equal 3, player_divs.length

          within(player_divs[0]) do
            assert_selector "span:not(.fw-bold)", text: "Alice"
          end

          within(player_divs[1]) do
            assert_selector "span:not(.fw-bold)", text: "Bob"
          end

          within(player_divs[2]) do
            assert_selector "span.fw-bold", text: "Mia"
          end
        end
      end

      # Verify Bob sees Mia's name change via broadcast
      using_session("default") do
        within("#players", wait: 5) do
          player_divs = all("div[id^='player_']")
          assert_equal 3, player_divs.length

          within(player_divs[0]) do
            assert_selector "span:not(.fw-bold)", text: "Alice"
          end

          within(player_divs[1]) do
            assert_selector "span.fw-bold", text: "Bob"
          end

          within(player_divs[2]) do
            assert_selector "span:not(.fw-bold)", text: "Mia"
          end
        end
      end

      # Verify Alice sees Mia's name change via broadcast
      using_session("charlie") do
        within("#players", wait: 5) do
          player_divs = all("div[id^='player_']")
          assert_equal 3, player_divs.length

          within(player_divs[0]) do
            assert_selector "span.fw-bold", text: "Alice"
          end

          within(player_divs[1]) do
            assert_selector "span:not(.fw-bold)", text: "Bob"
          end

          within(player_divs[2]) do
            assert_selector "span:not(.fw-bold)", text: "Mia"
          end
        end
      end
    end
  end
end
