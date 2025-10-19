# frozen_string_literal: true

require "application_system_test_case"

module LoadedQuestions
  class GamesTest < ApplicationSystemTestCase
    test "complete game flow with answer swapping" do
      # Create a new game with Mia as guesser (middle alphabetically)
      visit new_loaded_questions_game_path

      fill_in "Player name", with: "Mia"
      fill_in "Question", with: "What is your favorite color?"
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
        click_on "Create New Player"

        # Zoe should see the answer form
        assert_text "What is your favorite color?"

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
        click_on "Create New Player"

        # Alice should see the answer form
        assert_text "What is your favorite color?"

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
            assert_selector "i.bi-check-square", count: 1 # Checkmark
            assert_selector "span.fw-bold", text: "Alice"
          end
        end
      end

      # Verify all sessions see Alice's checkmark
      using_session("default") do
        within("#players") do
          player_divs = all("div[id^='player_']", wait: 5)
          within(player_divs[0]) do
            assert_selector "i.bi-check-square", count: 1
            assert_selector "span:not(.fw-bold)", text: "Alice"
          end
        end
      end

      using_session("zoe") do
        within("#players") do
          player_divs = all("div[id^='player_']", wait: 5)
          within(player_divs[0]) do
            assert_selector "i.bi-check-square", count: 1
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
            assert_selector "i.bi-check-square", count: 1
            assert_selector "span.fw-bold", text: "Zoe"
          end
        end
      end

      # Verify all sessions see both checkmarks
      using_session("default") do
        within("#players") do
          player_divs = all("div[id^='player_']", wait: 5)
          within(player_divs[0]) do
            assert_selector "i.bi-check-square", count: 1
            assert_selector "span:not(.fw-bold)", text: "Alice"
          end
          within(player_divs[2]) do
            assert_selector "i.bi-check-square", count: 1
            assert_selector "span:not(.fw-bold)", text: "Zoe"
          end
        end
      end

      using_session("alice") do
        within("#players") do
          player_divs = all("div[id^='player_']", wait: 5)
          within(player_divs[2]) do
            assert_selector "i.bi-check-square", count: 1
            assert_selector "span:not(.fw-bold)", text: "Zoe"
          end
        end
      end

      # Back to Mia - she should be able to start matching
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
        assert_text "Alice"
        assert_text "Zoe"

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

      # Verify Alice (non-guesser) sees the swapped order via broadcast
      using_session("alice") do
        # Wait for the broadcast to update Alice's view
        sleep 0.5

        # Alice should see the same swapped order that Mia sees
        guessed_answers = all(".swap-item")
        assert_equal 2, guessed_answers.length
        assert_equal answer2_original, guessed_answers[0].text,
          "Alice should see swapped order - first position"
        assert_equal answer1_original, guessed_answers[1].text,
          "Alice should see swapped order - second position"
      end

      # Complete the matching round
      using_session("default") do
        click_on "Complete Matching"
        within("dialog[open]") do
          click_on "Yes, I am sure"
        end

        # Wait for completed view to load
        assert_text "Score =", wait: 10

        # Mia (guesser) should NOT see "Create Next Turn" button
        assert_no_link "Create Next Turn"
      end

      # Verify all three sessions see the completed view with same results
      using_session("default") do
        # Wait for page to fully load
        assert_text "Mia's Score =", wait: 5

        # Store Mia's view for comparison
        assert_text "Alice"
        assert_text "Zoe"
        assert_text "Blue"
        assert_text "Red"

        # Extract the score from the card
        mia_score_text = find(".card-text", text: /Score =/).text
        assert_match(/Mia's Score = \d+/, mia_score_text)
      end

      using_session("alice") do
        # Wait for broadcast to show completed view
        assert_text "Mia's Score =", wait: 5

        # Alice should see the same content
        assert_text "Alice"
        assert_text "Zoe"
        assert_text "Blue"
        assert_text "Red"

        # Should see "Create Next Turn" button (non-guesser)
        assert_link "Create Next Turn"

        # Extract Alice's score text
        alice_score_text = find(".card-text", text: /Score =/).text

        # Score should match what Mia saw
        using_session("default") do
          mia_score_text = find(".card-text", text: /Score =/).text
          assert_equal mia_score_text, alice_score_text,
            "Alice should see same score as Mia"
        end
      end

      using_session("zoe") do
        # Wait for broadcast to show completed view
        assert_text "Mia's Score =", wait: 5

        # Zoe should see the same content
        assert_text "Alice"
        assert_text "Zoe"
        assert_text "Blue"
        assert_text "Red"

        # Should see "Create Next Turn" button (non-guesser)
        assert_link "Create Next Turn"

        # Extract Zoe's score text
        zoe_score_text = find(".card-text", text: /Score =/).text

        # Score should match what Mia saw
        using_session("default") do
          mia_score_text = find(".card-text", text: /Score =/).text
          assert_equal mia_score_text, zoe_score_text,
            "Zoe should see same score as Mia"
        end
      end

      # Alice creates a new round and becomes the guesser
      using_session("alice") do
        click_on "Create Next Turn"

        # Should see the new round form
        assert_field "Question"

        # Fill in new question
        fill_in "Question", with: "What is your dream vacation?"
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
