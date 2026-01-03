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

      # Get the game id from URL for joining as other players
      game_id = current_path.split("/").last

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
        visit new_loaded_questions_game_player_path(game_id)
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
        visit new_loaded_questions_game_player_path(game_id)
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

      # Back to Mia (guesser) - she should be able to start matching
      using_session("default") do
        # Mia (guesser) should see Begin Guessing button
        assert_button "Begin Guessing"

        # Start the guessing round
        click_on "Begin Guessing"
        within("dialog[open]") do
          click_on "Yes, I am ready"
        end

        # Guesser should see all answers and player names
        # Pool answers are sorted alphabetically: Blue, Red
        # Player slots are sorted alphabetically: Alice, Zoe
        assert_text "Blue", wait: 5
        assert_text "Red"
        assert_text "Alice"
        assert_text "Zoe"

        # Mia (guesser) should see Complete Matching button
        assert_button "Complete Matching"

        # Guesser initial state: both answers in pool, both player slots empty
        pool = find(".answer-pool")
        alice_row = find(".fw-bold", text: "Alice").find(:xpath, "..")
        zoe_row = find(".fw-bold", text: "Zoe").find(:xpath, "..")

        assert_equal 2, pool.all(".answer-card").length
        within(alice_row) { assert_equal 0, all(".answer-card").length }
        within(zoe_row) { assert_equal 0, all(".answer-card").length }
      end

      # Verify Alice (non-guesser) sees initial state
      using_session("alice") do
        within("#guesses-display", wait: 5) do
          assert_text "Unassigned Answers"
          assert_text "Blue"
          assert_text "Red"
          # Non-guesser: both Alice and Zoe show "No answer assigned"
          alice_row = find(".fw-bold", text: "Alice").find(:xpath, "..")
          zoe_row = find(".fw-bold", text: "Zoe").find(:xpath, "..")
          within(alice_row) { assert_text "No answer assigned" }
          within(zoe_row) { assert_text "No answer assigned" }
        end
        # Non-guesser should NOT see Complete Matching button
        assert_no_button "Complete Matching"
      end

      # =========================================================
      # PERMUTATION 1: Guesser drags answer from pool to empty slot
      # =========================================================
      using_session("default") do
        pool = find(".answer-pool")
        alice_row = find(".fw-bold", text: "Alice").find(:xpath, "..")
        alice_slot = alice_row.find(".player-slot")

        # Guesser drags "Blue" from pool to Alice's empty slot
        blue_answer = pool.find(".answer-card", text: "Blue")
        blue_answer.drag_to(alice_slot)
        sleep 0.5

        # Guesser verifies: Blue in Alice's slot, Red still in pool
        pool = find(".answer-pool")
        assert_equal 1, pool.all(".answer-card").length
        within(pool) { assert_text "Red" }
        within(alice_row) { assert_selector ".answer-card", text: "Blue" }
      end

      # Verify Alice (non-guesser) sees the same state
      using_session("alice") do
        within("#guesses-display", wait: 5) do
          # Non-guesser: only Red is unassigned (Blue was assigned to Alice)
          unassigned_section =
            find("h6", text: "Unassigned Answers").find(:xpath, "..")
          within(unassigned_section) do
            assert_text "Red"
            assert_no_text "Blue"
          end
          # Non-guesser: Alice has Blue assigned, Zoe has none
          alice_row = find(".fw-bold", text: "Alice").find(:xpath, "..")
          zoe_row = find(".fw-bold", text: "Zoe").find(:xpath, "..")
          within(alice_row) { assert_text "Blue" }
          within(zoe_row) { assert_text "No answer assigned" }
        end
      end

      # =========================================================
      # PERMUTATION 2: Guesser drags answer from slot to empty slot
      # =========================================================
      using_session("default") do
        alice_row = find(".fw-bold", text: "Alice").find(:xpath, "..")
        zoe_row = find(".fw-bold", text: "Zoe").find(:xpath, "..")
        alice_slot = alice_row.find(".player-slot")
        zoe_slot = zoe_row.find(".player-slot")

        # Guesser drags "Blue" from Alice's slot to Zoe's empty slot
        blue_answer = alice_slot.find(".answer-card", text: "Blue")
        blue_answer.drag_to(zoe_slot)
        sleep 0.5

        # Guesser verifies: Alice empty, Zoe has Blue, Red still in pool
        pool = find(".answer-pool")
        assert_equal 1, pool.all(".answer-card").length
        within(pool) { assert_text "Red" }
        within(alice_row) { assert_equal 0, all(".answer-card").length }
        within(zoe_row) { assert_selector ".answer-card", text: "Blue" }
      end

      # Verify Zoe (non-guesser) sees the same state
      using_session("zoe") do
        within("#guesses-display", wait: 5) do
          # Non-guesser: Red is unassigned
          assert_text "Unassigned Answers"
          assert_text "Red"
          # Non-guesser: Alice has no answer, Zoe has Blue
          alice_row = find(".fw-bold", text: "Alice").find(:xpath, "..")
          zoe_row = find(".fw-bold", text: "Zoe").find(:xpath, "..")
          within(alice_row) { assert_text "No answer assigned" }
          within(zoe_row) { assert_text "Blue" }
        end
        # Non-guesser should NOT see Complete Matching button
        assert_no_button "Complete Matching"
      end

      # Setup for permutation 3: Guesser assigns Red to Alice so both have
      # answers
      using_session("default") do
        pool = find(".answer-pool")
        alice_row = find(".fw-bold", text: "Alice").find(:xpath, "..")
        alice_slot = alice_row.find(".player-slot")

        red_answer = pool.find(".answer-card", text: "Red")
        red_answer.drag_to(alice_slot)
        sleep 0.5

        # Guesser verifies: Alice has Red, Zoe has Blue, pool empty
        pool = find(".answer-pool")
        zoe_row = find(".fw-bold", text: "Zoe").find(:xpath, "..")
        assert_equal 0, pool.all(".answer-card").length
        within(alice_row) { assert_selector ".answer-card", text: "Red" }
        within(zoe_row) { assert_selector ".answer-card", text: "Blue" }
      end

      # Verify Alice (non-guesser) sees both assigned
      using_session("alice") do
        within("#guesses-display", wait: 5) do
          # Non-guesser: no unassigned answers
          assert_no_text "Unassigned Answers"
          assert_no_text "No answer assigned"
          # Non-guesser: Alice has Red, Zoe has Blue
          alice_row = find(".fw-bold", text: "Alice").find(:xpath, "..")
          zoe_row = find(".fw-bold", text: "Zoe").find(:xpath, "..")
          within(alice_row) { assert_text "Red" }
          within(zoe_row) { assert_text "Blue" }
        end
      end

      # =========================================================
      # PERMUTATION 3: Guesser drags answer from slot to slot with
      # existing answer (displaced answer goes back to pool)
      # =========================================================
      using_session("default") do
        alice_row = find(".fw-bold", text: "Alice").find(:xpath, "..")
        zoe_row = find(".fw-bold", text: "Zoe").find(:xpath, "..")
        alice_slot = alice_row.find(".player-slot")
        zoe_slot = zoe_row.find(".player-slot")

        # Guesser drags "Blue" from Zoe's slot to Alice's slot (which has Red)
        # Expected: Red goes back to pool, Blue goes to Alice
        blue_answer = zoe_slot.find(".answer-card", text: "Blue")
        blue_answer.drag_to(alice_slot)
        sleep 0.5

        # Guesser verifies: Alice has Blue, Zoe empty, Red in pool
        pool = find(".answer-pool")
        assert_equal 1, pool.all(".answer-card").length
        within(pool) { assert_text "Red" }
        within(alice_row) { assert_selector ".answer-card", text: "Blue" }
        within(zoe_row) { assert_equal 0, all(".answer-card").length }
      end

      # Verify Alice (non-guesser) sees the displaced answer in pool
      using_session("alice") do
        within("#guesses-display", wait: 5) do
          # Non-guesser: Red is now unassigned (was displaced)
          assert_text "Unassigned Answers"
          assert_text "Red"
          # Non-guesser: Alice has Blue, Zoe has none
          alice_row = find(".fw-bold", text: "Alice").find(:xpath, "..")
          zoe_row = find(".fw-bold", text: "Zoe").find(:xpath, "..")
          within(alice_row) { assert_text "Blue" }
          within(zoe_row) { assert_text "No answer assigned" }
        end
      end

      # =========================================================
      # PERMUTATION 4: Guesser drags answer from slot back to pool
      # =========================================================
      using_session("default") do
        pool = find(".answer-pool")
        alice_row = find(".fw-bold", text: "Alice").find(:xpath, "..")
        alice_slot = alice_row.find(".player-slot")

        # Guesser drags "Blue" from Alice's slot back to pool
        blue_answer = alice_slot.find(".answer-card", text: "Blue")
        blue_answer.drag_to(pool)
        sleep 0.5

        # Guesser verifies: both answers in pool, both slots empty
        pool = find(".answer-pool")
        zoe_row = find(".fw-bold", text: "Zoe").find(:xpath, "..")
        assert_equal 2, pool.all(".answer-card").length
        within(pool) { assert_text "Blue" }
        within(pool) { assert_text "Red" }
        within(alice_row) { assert_equal 0, all(".answer-card").length }
        within(zoe_row) { assert_equal 0, all(".answer-card").length }
      end

      # Verify Zoe (non-guesser) sees both unassigned
      using_session("zoe") do
        within("#guesses-display", wait: 5) do
          # Non-guesser: both answers unassigned
          assert_text "Unassigned Answers"
          assert_text "Blue"
          assert_text "Red"
          # Non-guesser: both players have no answer
          alice_row = find(".fw-bold", text: "Alice").find(:xpath, "..")
          zoe_row = find(".fw-bold", text: "Zoe").find(:xpath, "..")
          within(alice_row) { assert_text "No answer assigned" }
          within(zoe_row) { assert_text "No answer assigned" }
        end
      end

      # =========================================================
      # PERMUTATION 5: Guesser clicks X button to unassign answer
      # =========================================================

      # First assign Blue to Alice so we have something to unassign
      using_session("default") do
        pool = find(".answer-pool")
        alice_row = find(".fw-bold", text: "Alice").find(:xpath, "..")
        alice_slot = alice_row.find(".player-slot")

        blue_answer = pool.find(".answer-card", text: "Blue")
        blue_answer.drag_to(alice_slot)
        sleep 0.5

        # Guesser verifies: Blue in Alice's slot
        within(alice_row) { assert_selector ".answer-card", text: "Blue" }
      end

      # Now click the X button to unassign
      using_session("default") do
        alice_row = find(".fw-bold", text: "Alice").find(:xpath, "..")
        alice_slot = alice_row.find(".player-slot")

        # Guesser clicks the X button on Blue answer in Alice's slot
        within(alice_slot) do
          find(".answer-card", text: "Blue").find(".unassign-btn").click
        end
        sleep 0.5

        # Guesser verifies: Blue back in pool, Alice's slot empty
        pool = find(".answer-pool")
        assert_equal 2, pool.all(".answer-card").length
        within(pool) { assert_text "Blue" }
        within(pool) { assert_text "Red" }
        within(alice_row) { assert_equal 0, all(".answer-card").length }
      end

      # Verify Alice (non-guesser) sees the unassignment
      using_session("alice") do
        within("#guesses-display", wait: 5) do
          # Non-guesser: both answers back in unassigned
          assert_text "Unassigned Answers"
          assert_text "Blue"
          assert_text "Red"
          # Non-guesser: Alice has no answer
          alice_row = find(".fw-bold", text: "Alice").find(:xpath, "..")
          within(alice_row) { assert_text "No answer assigned" }
        end
      end

      # =========================================================
      # Guesser assigns correct answers and verifies persistence
      # =========================================================
      using_session("default") do
        pool = find(".answer-pool")
        alice_row = find(".fw-bold", text: "Alice").find(:xpath, "..")
        zoe_row = find(".fw-bold", text: "Zoe").find(:xpath, "..")
        alice_slot = alice_row.find(".player-slot")
        zoe_slot = zoe_row.find(".player-slot")

        # Guesser assigns correct answers: Alice wrote Blue, Zoe wrote Red
        blue_answer = pool.find(".answer-card", text: "Blue")
        blue_answer.drag_to(alice_slot)
        sleep 0.5

        pool = find(".answer-pool")
        red_answer = pool.find(".answer-card", text: "Red")
        red_answer.drag_to(zoe_slot)
        sleep 0.5

        # Guesser verifies correct assignments
        within(alice_row) { assert_selector ".answer-card", text: "Blue" }
        within(zoe_row) { assert_selector ".answer-card", text: "Red" }

        # Refresh to verify assignments persisted
        visit current_path
        assert_text "Blue", wait: 5
        assert_text "Red"

        # Guesser verifies assignments are maintained after refresh
        alice_row = find(".fw-bold", text: "Alice").find(:xpath, "..")
        zoe_row = find(".fw-bold", text: "Zoe").find(:xpath, "..")
        within(alice_row) { assert_selector ".answer-card", text: "Blue" }
        within(zoe_row) { assert_selector ".answer-card", text: "Red" }
      end

      # Verify Alice (non-guesser) sees correct final state
      using_session("alice") do
        within("#guesses-display", wait: 5) do
          assert_no_text "Unassigned Answers"
          assert_no_text "No answer assigned"
          alice_row = find(".fw-bold", text: "Alice").find(:xpath, "..")
          zoe_row = find(".fw-bold", text: "Zoe").find(:xpath, "..")
          within(alice_row) { assert_text "Blue" }
          within(zoe_row) { assert_text "Red" }
        end
      end

      # Verify Zoe (non-guesser) sees correct final state
      using_session("zoe") do
        within("#guesses-display", wait: 5) do
          assert_no_text "Unassigned Answers"
          assert_no_text "No answer assigned"
          alice_row = find(".fw-bold", text: "Alice").find(:xpath, "..")
          zoe_row = find(".fw-bold", text: "Zoe").find(:xpath, "..")
          within(alice_row) { assert_text "Blue" }
          within(zoe_row) { assert_text "Red" }
        end
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

      game_id = current_path.split("/").last

      # Try to join with a name that's the same but with emoji
      using_session("bob") do
        visit new_loaded_questions_game_player_path(game_id)
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
        visit new_loaded_questions_game_player_path(game_id)
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

        # =========================================================
        # Test: Backend 5xx error causes page reload and state reset
        # =========================================================

        # Verify initial state: both answers in pool, both slots empty
        pool = find(".answer-pool")
        assert_equal 2, pool.all(".answer-card").length
        bob_row = find(".fw-bold", text: "Bob").find(:xpath, "..")
        charlie_row = find(".fw-bold", text: "Charlie").find(:xpath, "..")
        within(bob_row) { assert_equal 0, all(".answer-card").length }
        within(charlie_row) { assert_equal 0, all(".answer-card").length }

        # Patch Capybara to ignore our simulated error
        # See: https://makandracards.com/makandra/496074
        ignore_error_module = Module.new do
          def raise_server_error!
            super
          rescue StandardError => e
            raise e unless e.message.include?("Simulated backend error")
          end
        end
        Capybara::Session.prepend(ignore_error_module)

        begin
          # Stub save! to raise an error (simulating backend 5xx)
          LoadedQuestions::Game.any_instance
            .stubs(:save!)
            .raises(StandardError, "Simulated backend error")

          # Attempt to drag an answer - this will trigger the 500 error
          inception = pool.find(".answer-card", text: "Inception")
          inception.drag_to(bob_row.find(".player-slot"))

          # Wait for page reload to complete
          # The Stimulus controller calls window.location.reload() on error
          sleep 2

          # Wait for the page to fully reload by checking for fresh elements
          assert_selector ".answer-pool", wait: 10
          assert_text "The Matrix", wait: 5
          assert_text "Inception"
        ensure
          # Remove the stub
          LoadedQuestions::Game.any_instance.unstub(:save!)
        end

        # Verify state is restored: both answers back in pool after reload
        pool = find(".answer-pool")
        assert_equal 2, pool.all(".answer-card").length
        within(pool) { assert_text "Inception" }
        within(pool) { assert_text "The Matrix" }

        # Verify both slots are still empty
        bob_row = find(".fw-bold", text: "Bob").find(:xpath, "..")
        charlie_row = find(".fw-bold", text: "Charlie").find(:xpath, "..")
        within(bob_row) { assert_equal 0, all(".answer-card").length }
        within(charlie_row) { assert_equal 0, all(".answer-card").length }

        # =========================================================
        # Continue with normal flow: Assign answers to players
        # =========================================================

        # Players (non-guessers) sorted alphabetically: Bob, Charlie
        # Answers sorted alphabetically: Inception, The Matrix
        pool = find(".answer-pool")
        bob_row = find(".fw-bold", text: "Bob").find(:xpath, "..")
        charlie_row = find(".fw-bold", text: "Charlie").find(:xpath, "..")

        inception = pool.find(".answer-card", text: "Inception")
        inception.drag_to(bob_row.find(".player-slot"))
        sleep 0.5

        pool = find(".answer-pool")
        the_matrix = pool.find(".answer-card", text: "The Matrix")
        the_matrix.drag_to(charlie_row.find(".player-slot"))
        sleep 0.5

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
      game_id = current_path.split("/").last

      # Charlie joins the game
      using_session("charlie") do
        visit new_loaded_questions_game_player_path(game_id)
        fill_in "Name", with: "Charlie"
        click_on "Join Game"
        assert_text "Charlie"
      end

      # Zoe joins the game
      using_session("zoe") do
        visit new_loaded_questions_game_player_path(game_id)
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

      # Have Alice and Mia submit answers to progress to matching
      using_session("charlie") do
        fill_in "player[answer]", with: "Blue"
        click_on "Submit Answer"

        # Wait for answer form to be hidden
        assert_selector "[data-reveal-target='item'].d-none", visible: :hidden,
          wait: 5
      end

      using_session("zoe") do
        fill_in "player[answer]", with: "Red"
        click_on "Submit Answer"

        # Wait for answer form to be hidden
        assert_selector "[data-reveal-target='item'].d-none", visible: :hidden,
          wait: 5
      end

      # Bob (guesser) starts the matching round
      using_session("default") do
        click_on "Begin Guessing"
        within("dialog[open]") do
          click_on "Yes, I am ready"
        end

        # Wait for matching view to load
        assert_text "Blue", wait: 5
        assert_text "Red"
        assert_button "Complete Matching"

        # Guesser: player names should be in alphabetical order (Alice, Mia)
        guessed_answer_names = all("[data-player-name-id]").map(&:text)
        assert_equal %w[Alice Mia], guessed_answer_names
      end

      # Alice (non-guesser) changes her name to Zara during matching
      # (after Mia alphabetically)
      using_session("charlie") do
        within("#players") do
          alice_div = find("div[id^='player_']", text: "Alice")
          within(alice_div) do
            find("a[title='Edit name']").click
          end
        end

        assert_text "Edit Your Name", wait: 5
        fill_in "Your Name", with: "Zara"
        click_on "Update Name"

        # Should be redirected back to matching view
        assert_text "Blue", wait: 5
        assert_text "Red"

        # Non-guesser: verify name updated in guesses display
        within("#guesses-display") do
          assert_selector "[data-player-name-id]", text: "Zara"
          assert_no_selector "[data-player-name-id]", text: "Alice"
        end
      end

      # Verify Bob (guesser) sees Zara's name change
      using_session("default") do
        assert_selector "[data-player-name-id]", text: "Zara", wait: 5
        assert_no_selector "[data-player-name-id]", text: "Alice"

        # Guesser: verify order has not changed - Zara is still first even
        # though alphabetically she should be after Mia
        guessed_answer_names = all("[data-player-name-id]").map(&:text)
        assert_equal %w[Zara Mia], guessed_answer_names
      end

      # Verify Mia (non-guesser) sees Zara's name change
      using_session("zoe") do
        within("#guesses-display", wait: 5) do
          assert_selector "[data-player-name-id]", text: "Zara"
          assert_no_selector "[data-player-name-id]", text: "Alice"

          # Non-guesser: verify order - Zara is still in first position
          guessed_answer_names = all("[data-player-name-id]").map(&:text)
          assert_equal %w[Zara Mia], guessed_answer_names
        end
      end

      # Refresh Bob's (guesser) page and verify order is maintained
      using_session("default") do
        visit current_path

        # Wait for page to reload
        assert_text "Blue", wait: 5
        assert_text "Red"

        # Guesser: verify order after refresh
        # (view sorts by name, so now Mia, Zara)
        guessed_answer_names = all("[data-player-name-id]").map(&:text)
        assert_equal %w[Mia Zara], guessed_answer_names
      end

      # Guesser assigns answers intentionally WRONG to test scoring
      # After refresh: Mia is first slot, Zara is second slot
      # Zara wrote Blue, Mia wrote Red
      # Assign incorrectly: Mia gets Blue (wrong), Zara gets Red (wrong)
      using_session("default") do
        pool = find(".answer-pool")
        player_slots = all(".player-slot")
        mia_slot = player_slots[0] # Mia is alphabetically first
        zara_slot = player_slots[1]

        blue_answer = pool.find(".answer-card", text: "Blue")
        blue_answer.drag_to(mia_slot)  # Wrong: Zara wrote Blue
        sleep 0.5

        pool = find(".answer-pool")
        red_answer = pool.find(".answer-card", text: "Red")
        red_answer.drag_to(zara_slot)  # Wrong: Mia wrote Red
        sleep 0.5

        # Complete the round with wrong guesses
        click_on "Complete Matching"
        within("dialog[open]") do
          click_on "Yes, I am sure"
        end

        # Wait for completed view
        assert_text "Score:", wait: 10
      end

      # Zara (non-guesser) changes name to Xena during completed phase
      # (still after Mia alphabetically)
      using_session("charlie") do
        # Wait for completed view
        assert_text "Score:", wait: 10

        within("#players") do
          zara_div = find("div[id^='player_']", text: "Zara")
          within(zara_div) do
            find("a[title='Edit name']").click
          end
        end

        assert_text "Edit Your Name", wait: 5
        fill_in "Your Name", with: "Xena"
        click_on "Update Name"

        # Should be redirected back to completed view
        assert_text "Score:", wait: 5

        # Verify name updated in completed answers
        # (both main name and "guessed: ..." text)
        within("#answers") do
          # Should see Xena twice (once as player name, once in
          # "guessed: ..." for wrong answer)
          assert_selector "[data-player-name-id]", text: "Xena", count: 2
          assert_no_text "Zara"
        end
      end

      # Verify Bob sees Xena's name change in completed answers
      # (including "guessed: ..." text)
      using_session("default") do
        within("#answers") do
          # Should see Xena twice in the answers section
          assert_selector "[data-player-name-id]", text: "Xena", count: 2,
            wait: 5
          assert_no_text "Zara"
        end
      end

      # Verify Mia sees Xena's name change in completed answers
      using_session("zoe") do
        # Wait for completed view
        assert_text "Score:", wait: 10

        within("#answers") do
          # Should see Xena twice in the answers section
          assert_selector "[data-player-name-id]", text: "Xena", count: 2,
            wait: 5
          assert_no_text "Zara"
        end
      end
    end
  end
end
