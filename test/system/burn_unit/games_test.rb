# frozen_string_literal: true

require "application_system_test_case"

module BurnUnit
  class GamesTest < ApplicationSystemTestCase
    test "complete game flow with players joining throughout and " \
      "name changes" do
      # Create a new game with Mia as judge (middle alphabetically)
      visit new_burn_unit_game_path

      fill_in "Your Name", with: "Mia"
      fill_in "First Question", with: "Who is most likely to win the lottery?"
      click_on "Create New Game"

      # Mia should see polling view as the judge
      assert_text "Who is most likely to win the lottery?"
      assert_text "Mia"
      assert_text "You're the Judge!"

      # Get the game id from URL for joining as other players
      game_id = current_path.split("/").last

      # Verify initial player list for Mia (only she exists at this point)
      using_session("default") do
        within("#players") do
          player_divs = all("div[id^='player_']")
          assert_equal 1, player_divs.length

          # Mia should have bold name (current player)
          within(player_divs[0]) do
            assert_selector "span.fw-bold", text: "Mia"
            # Score badge should show 0
            assert_selector ".badge", text: "0"
          end
        end

        # Verify vote form dropdown has no options (only Mia exists, can't vote
        # for self). Form is visible by default when player hasn't voted.
        within("select") do
          # Should only have the prompt option
          assert_selector "option", count: 1
          assert_selector "option", text: "Select a player..."
        end
      end

      # Zoe joins second (higher alphabetically - will display last)
      using_session("zoe") do
        visit new_burn_unit_game_player_path(game_id)
        fill_in "Name", with: "Zoe"
        click_on "Join Game"

        # Zoe should see the question and vote form
        assert_text "Who is most likely to win the lottery?"

        # Zoe should NOT see "You're the Judge!" (not the judge)
        assert_no_text "You're the Judge!"

        # Verify Zoe sees alphabetized player list: Mia, Zoe
        within("#players") do
          player_divs = all("div[id^='player_']")
          assert_equal 2, player_divs.length

          # First should be Mia
          within(player_divs[0]) do
            assert_selector "span:not(.fw-bold)", text: "Mia"
          end

          # Second should be Zoe (current player)
          within(player_divs[1]) do
            assert_selector "span.fw-bold", text: "Zoe"
          end
        end

        # Verify Zoe's vote dropdown shows Mia (only other playing player)
        # Form is visible by default when player hasn't voted.
        within("select") do
          assert_selector "option", text: "Mia"
          # Should NOT see Zoe (can't vote for self)
          assert_no_selector "option", text: "Zoe"
        end
      end

      # Verify Mia sees the updated alphabetized list and her dropdown now has
      # Zoe
      using_session("default") do
        within("#players") do
          # Wait for Zoe to appear via broadcast
          player_divs = all("div[id^='player_']")
          assert_equal 2, player_divs.length

          # First should be Mia (current player)
          within(player_divs[0]) do
            assert_selector "span.fw-bold", text: "Mia"
          end

          # Second should be Zoe
          within(player_divs[1]) do
            assert_selector "span:not(.fw-bold)", text: "Zoe"
          end
        end

        # Verify Mia's vote dropdown now shows Zoe
        within("select") do
          assert_selector "option", text: "Zoe", wait: 5
          # Should NOT see Mia (can't vote for self)
          assert_no_selector "option", text: "Mia"
        end
      end

      # Alice joins third (lower alphabetically - will display first)
      using_session("alice") do
        visit new_burn_unit_game_player_path(game_id)
        fill_in "Name", with: "Alice"
        click_on "Join Game"

        # Alice should see the question
        assert_text "Who is most likely to win the lottery?"

        # Verify Alice sees alphabetized player list: Alice, Mia, Zoe
        within("#players") do
          player_divs = all("div[id^='player_']")
          assert_equal 3, player_divs.length

          within(player_divs[0]) do
            assert_selector "span.fw-bold", text: "Alice" # Current player
          end

          within(player_divs[1]) do
            assert_selector "span:not(.fw-bold)", text: "Mia"
          end

          within(player_divs[2]) do
            assert_selector "span:not(.fw-bold)", text: "Zoe"
          end
        end

        # Verify Alice's vote dropdown shows Mia and Zoe
        # Form is visible by default when player hasn't voted.
        within("select") do
          options = all("option").map(&:text)
          assert_includes options, "Mia"
          assert_includes options, "Zoe"
          # Should NOT see Alice (can't vote for self)
          assert_not_includes options, "Alice"
        end
      end

      # Verify all sessions see the same alphabetized order: Alice, Mia, Zoe
      using_session("default") do
        within("#players") do
          player_divs = all("div[id^='player_']", wait: 5)
          assert_equal 3, player_divs.length

          within(player_divs[0]) do
            assert_selector "span:not(.fw-bold)", text: "Alice"
          end

          within(player_divs[1]) do
            assert_selector "span.fw-bold", text: "Mia"
          end

          within(player_divs[2]) do
            assert_selector "span:not(.fw-bold)", text: "Zoe"
          end
        end

        # Verify Mia's dropdown now shows Alice and Zoe
        within("select") do
          options = all("option").map(&:text)
          assert_includes options, "Alice"
          assert_includes options, "Zoe"
          assert_not_includes options, "Mia"
        end
      end

      using_session("zoe") do
        within("#players") do
          player_divs = all("div[id^='player_']", wait: 5)
          assert_equal 3, player_divs.length

          within(player_divs[0]) do
            assert_selector "span:not(.fw-bold)", text: "Alice"
          end

          within(player_divs[1]) do
            assert_selector "span:not(.fw-bold)", text: "Mia"
          end

          within(player_divs[2]) do
            assert_selector "span.fw-bold", text: "Zoe"
          end
        end

        # Verify Zoe's dropdown now shows Alice and Mia
        within("select") do
          options = all("option").map(&:text)
          assert_includes options, "Alice"
          assert_includes options, "Mia"
          assert_not_includes options, "Zoe"
        end
      end

      # Alice changes her name to Xena (will move to end alphabetically)
      using_session("alice") do
        within("#players") do
          alice_div = find("div[id^='player_']", text: "Alice")
          within(alice_div) do
            find("a[title='Edit name']").click
          end
        end

        assert_text "Edit Your Name", wait: 5
        fill_in "Your Name", with: "Xena"
        click_on "Update Name"

        # Should be redirected back to game
        assert_text "Who is most likely to win the lottery?", wait: 5

        # Verify player list is sorted: Mia, Xena, Zoe
        within("#players") do
          player_divs = all("div[id^='player_']")
          assert_equal 3, player_divs.length

          within(player_divs[0]) do
            assert_selector "span:not(.fw-bold)", text: "Mia"
          end

          within(player_divs[1]) do
            assert_selector "span.fw-bold", text: "Xena" # Current player
          end

          within(player_divs[2]) do
            assert_selector "span:not(.fw-bold)", text: "Zoe"
          end
        end

        # Verify vote dropdown shows updated names
        within("select") do
          options = all("option").map(&:text)
          assert_includes options, "Mia"
          assert_includes options, "Zoe"
          assert_not_includes options, "Xena"
          assert_not_includes options, "Alice" # Old name gone
        end
      end

      # Verify other sessions see the name change
      using_session("default") do
        within("#players") do
          player_divs = all("div[id^='player_']", wait: 5)
          assert_equal 3, player_divs.length

          within(player_divs[0]) do
            assert_selector "span.fw-bold", text: "Mia"
          end

          within(player_divs[1]) do
            assert_selector "span:not(.fw-bold)", text: "Xena"
          end

          within(player_divs[2]) do
            assert_selector "span:not(.fw-bold)", text: "Zoe"
          end
        end

        # Verify Mia's dropdown shows updated names
        within("select") do
          assert_selector "option", text: "Xena", wait: 5
          assert_no_selector "option", text: "Alice"
        end
      end

      using_session("zoe") do
        within("#players") do
          player_divs = all("div[id^='player_']", wait: 5)
          assert_equal 3, player_divs.length

          within(player_divs[0]) do
            assert_selector "span:not(.fw-bold)", text: "Mia"
          end

          within(player_divs[1]) do
            assert_selector "span:not(.fw-bold)", text: "Xena"
          end

          within(player_divs[2]) do
            assert_selector "span.fw-bold", text: "Zoe"
          end
        end

        # Verify Zoe's dropdown shows updated names
        within("select") do
          assert_selector "option", text: "Xena", wait: 5
          assert_no_selector "option", text: "Alice"
        end
      end

      # Mia submits a vote for Xena
      using_session("default") do
        select "Xena", from: "player[candidate_id]"
        click_on "Submit Vote"

        # Wait for vote to be submitted
        sleep 0.5

        # Verify Mia now has a checkmark
        within("#players") do
          mia_div = find("div[id^='player_']", text: "Mia")
          within(mia_div) do
            assert_selector "i.bi-check-square-fill", count: 1
          end
        end
      end

      # Verify all sessions see Mia's checkmark
      using_session("alice") do
        within("#players") do
          mia_div = find("div[id^='player_']", text: "Mia", wait: 5)
          within(mia_div) do
            assert_selector "i.bi-check-square-fill", count: 1
          end
        end
      end

      using_session("zoe") do
        within("#players") do
          mia_div = find("div[id^='player_']", text: "Mia", wait: 5)
          within(mia_div) do
            assert_selector "i.bi-check-square-fill", count: 1
          end
        end
      end

      # Xena submits a vote for Zoe
      using_session("alice") do
        select "Zoe", from: "player[candidate_id]"
        click_on "Submit Vote"

        # Wait for vote to be submitted
        sleep 0.5

        # Verify Xena now has a checkmark
        within("#players") do
          xena_div = find("div[id^='player_']", text: "Xena")
          within(xena_div) do
            assert_selector "i.bi-check-square-fill", count: 1
          end
        end
      end

      # Verify Xena's checkmark is visible to others
      using_session("default") do
        within("#players") do
          xena_div = find("div[id^='player_']", text: "Xena", wait: 5)
          within(xena_div) do
            assert_selector "i.bi-check-square-fill", count: 1
          end
        end
      end

      # Zoe submits a vote for Xena (Xena will be the winner with 2 votes)
      using_session("zoe") do
        select "Xena", from: "player[candidate_id]"
        click_on "Submit Vote"

        # Wait for vote to be submitted
        sleep 0.5

        # Verify Zoe now has a checkmark
        within("#players") do
          zoe_div = find("div[id^='player_']", text: "Zoe")
          within(zoe_div) do
            assert_selector "i.bi-check-square-fill", count: 1
          end
        end
      end

      # Verify all players have checkmarks on all screens
      using_session("default") do
        within("#players") do
          # All 3 players should have checkmarks
          assert_selector "i.bi-check-square-fill", count: 3, wait: 5
        end
      end

      using_session("alice") do
        within("#players") do
          assert_selector "i.bi-check-square-fill", count: 3, wait: 5
        end
      end

      # Mia (judge) tallies the votes
      using_session("default") do
        click_on "Tally Votes"
        within("dialog[open]") do
          click_on "Yes, tally votes"
        end

        # Should see the results
        assert_text "Results", wait: 5

        # Xena should be the winner with 2 votes
        within("#candidates") do
          # First candidate should be Xena (winner, 2 votes)
          candidates = all(".list-group-item")
          within(candidates[0]) do
            assert_selector "i.bi-trophy-fill" # Winner trophy
            assert_text "Xena"
            assert_text "2 votes"
            assert_text "Mia"
            assert_text "Zoe"
          end

          # Second candidate should be Zoe (1 vote)
          within(candidates[1]) do
            assert_no_selector "i.bi-trophy-fill"
            assert_text "Zoe"
            assert_text "1 vote"
            assert_text "Xena"
          end

          # Third candidate should be Mia (0 votes)
          within(candidates[2]) do
            assert_no_selector "i.bi-trophy-fill"
            assert_text "Mia"
            assert_text "0 votes"
            assert_text "No votes"
          end
        end

        # Mia (judge) should NOT see Create Next Round button
        assert_no_link "Create Next Round"

        # Verify Xena's score is now 1
        within("#players") do
          xena_div = find("div[id^='player_']", text: "Xena")
          within(xena_div) do
            assert_selector ".badge", text: "1"
          end
        end
      end

      # Verify non-judges see the results and can create next round
      using_session("alice") do
        assert_text "Results", wait: 5

        # Verify results match
        within("#candidates") do
          candidates = all(".list-group-item")
          within(candidates[0]) do
            assert_selector "i.bi-trophy-fill"
            assert_text "Xena"
            assert_text "2 votes"
          end
        end

        # Xena should see Create Next Round button (non-judge)
        assert_link "Create Next Round"

        # Verify score badges are updated
        within("#players") do
          xena_div = find("div[id^='player_']", text: "Xena")
          within(xena_div) do
            assert_selector ".badge", text: "1"
          end

          mia_div = find("div[id^='player_']", text: "Mia")
          within(mia_div) do
            assert_selector ".badge", text: "0"
          end

          zoe_div = find("div[id^='player_']", text: "Zoe")
          within(zoe_div) do
            assert_selector ".badge", text: "0"
          end
        end
      end

      using_session("zoe") do
        assert_text "Results", wait: 5
        assert_link "Create Next Round"
      end

      # Zoe creates the next round and becomes the judge
      using_session("zoe") do
        click_on "Create Next Round"

        # Should see the new round form
        assert_field "Question"

        fill_in "Question", with: "Who would survive in a zombie apocalypse?"
        click_on "Start Round"

        # Should see the new question
        assert_text "Who would survive in a zombie apocalypse?", wait: 5

        # Zoe should now be the judge
        assert_text "You're the Judge!"

        # Verify player list resets (no checkmarks, Zoe is current player)
        within("#players") do
          player_divs = all("div[id^='player_']")
          assert_equal 3, player_divs.length

          # All should have empty boxes (no votes yet)
          assert_selector "i.bi-square", count: 3
          assert_no_selector "i.bi-check-square-fill"

          # Verify Zoe is bold (current player)
          within(player_divs[2]) do
            assert_selector "span.fw-bold", text: "Zoe"
          end
        end
      end

      # Verify Mia sees the new round via broadcast
      using_session("default") do
        assert_text "Who would survive in a zombie apocalypse?", wait: 5

        # Mia should NOT see "You're the Judge!"
        assert_no_text "You're the Judge!"

        # Mia should see the vote form
        assert_button "Show / Hide Vote"

        # Verify player list reset
        within("#players") do
          assert_selector "i.bi-square", count: 3
          assert_no_selector "i.bi-check-square-fill"
        end
      end

      # Verify Xena sees the new round via broadcast
      using_session("alice") do
        assert_text "Who would survive in a zombie apocalypse?", wait: 5

        # Xena should NOT see "You're the Judge!"
        assert_no_text "You're the Judge!"

        # Xena should see the vote form
        assert_button "Show / Hide Vote"
      end
    end

    test "validation errors and edge cases" do
      # Try to create a game with invalid inputs (too short)
      visit new_burn_unit_game_path

      fill_in "Your Name", with: "A"
      fill_in "First Question", with: "Q"
      click_on "Create New Game"

      # Should see validation errors under the inputs
      assert_text "is too short", count: 2
      assert_selector ".invalid-feedback", count: 2

      # Create game successfully with valid inputs
      fill_in "Your Name", with: "Alice"
      fill_in "First Question", with: "Who is most likely to forget their keys?"
      click_on "Create New Game"

      # Should see the game view
      assert_text "Who is most likely to forget their keys?"
      assert_text "Alice"
      assert_text "You're the Judge!"

      game_id = current_path.split("/").last

      # Try to join with a name that's the same but with emoji
      using_session("bob") do
        visit new_burn_unit_game_player_path(game_id)
        fill_in "Name", with: "Alice 😀"
        click_on "Join Game"

        # Should see validation error about duplicate name
        assert_text "has already been taken"
        assert_selector ".invalid-feedback", count: 1

        # Join with a valid unique name
        fill_in "Name", with: "Bob"
        click_on "Join Game"

        # Should see the game view
        assert_text "Who is most likely to forget their keys?"

        # Bob submits a vote
        select "Alice", from: "player[candidate_id]"
        click_on "Submit Vote"
        sleep 0.5
      end

      # Back to Alice (judge) - try to tally with only 1 vote
      using_session("default") do
        # Wait for Bob's vote to be broadcast
        within("#players") do
          assert_selector "i.bi-check-square-fill", count: 1, wait: 5
        end

        # Open the Tally Votes modal
        click_on "Tally Votes"
        assert_selector "dialog[open]", visible: true

        # Try to submit with insufficient votes
        within("dialog[open]") do
          click_on "Yes, tally votes"
        end

        # Should see error message about needing more votes
        assert_selector ".alert-danger", wait: 5
        assert_text "Need at least 2 votes to tally"

        # Modal should be closed
        assert_no_selector "dialog[open]"

        # Should still be on polling view with Tally Votes button
        assert_button "Tally Votes"
      end

      # Charlie joins and votes
      using_session("charlie") do
        visit new_burn_unit_game_player_path(game_id)
        fill_in "Name", with: "Charlie"
        click_on "Join Game"

        # Should see the vote form
        assert_text "Who is most likely to forget their keys?"

        # Verify Charlie sees all players in alphabetical order
        within("#players") do
          player_divs = all("div[id^='player_']")
          assert_equal 3, player_divs.length

          within(player_divs[0]) do
            assert_selector "span:not(.fw-bold)", text: "Alice"
          end

          within(player_divs[1]) do
            # Bob has voted
            assert_selector "i.bi-check-square-fill"
            assert_selector "span:not(.fw-bold)", text: "Bob"
          end

          within(player_divs[2]) do
            # Charlie hasn't voted yet
            assert_selector "i.bi-square"
            assert_selector "span.fw-bold", text: "Charlie"
          end
        end

        # Charlie votes
        select "Bob", from: "player[candidate_id]"
        click_on "Submit Vote"
        sleep 0.5
      end

      # Verify Alice sees both votes now
      using_session("default") do
        within("#players") do
          assert_selector "i.bi-check-square-fill", count: 2, wait: 5
        end
      end

      # Test dialog cancel behaviors
      using_session("default") do
        # Open the Tally Votes modal
        click_on "Tally Votes"
        assert_selector "dialog[open]", visible: true
        assert_text "Are you ready to tally the votes?"

        # Click the X button to close
        click_button(class: "btn-close")
        assert_no_selector "dialog[open]", wait: 2

        # Should still be on polling view
        assert_button "Tally Votes"

        # Open modal again
        click_on "Tally Votes"
        assert_selector "dialog[open]", visible: true

        # Click the Close button
        within("dialog[open]") do
          click_on "Close"
        end
        assert_no_selector "dialog[open]", wait: 2

        # Should still be on polling view
        assert_button "Tally Votes"

        # Open modal again and confirm this time
        click_on "Tally Votes"
        within("dialog[open]") do
          click_on "Yes, tally votes"
        end

        # Should transition to completed view
        assert_no_selector "dialog[open]", wait: 2
        assert_text "Results", wait: 5

        # Alice (judge) should NOT see Create Next Round button
        assert_no_link "Create Next Round"
      end

      # Bob tries to create a new round with invalid question
      using_session("bob") do
        # Wait for broadcast to show completed view
        assert_text "Results", wait: 5

        # Bob should see Create Next Round button (non-judge)
        assert_link "Create Next Round"

        # Click to create new round
        click_on "Create Next Round"

        # Should see the new round form
        assert_field "Question"

        # Try to submit with 1-letter question
        fill_in "Question", with: "Q"
        click_on "Start Round"

        # Should see validation error
        assert_text "is too short"
        assert_selector ".invalid-feedback", count: 1

        # Fill in valid question
        fill_in "Question", with: "Who would win in an eating contest?"
        click_on "Start Round"

        # Should see the new question
        assert_text "Who would win in an eating contest?", wait: 5

        # Bob should now be the judge
        assert_text "You're the Judge!"
      end

      # Verify Alice sees the new round via broadcast
      using_session("default") do
        assert_text "Who would win in an eating contest?", wait: 5
        assert_no_text "You're the Judge!"
      end

      # Verify Charlie sees the new round via broadcast
      using_session("charlie") do
        assert_text "Who would win in an eating contest?", wait: 5
        assert_no_text "You're the Judge!"
      end

      # Test name editing validation errors
      using_session("charlie") do
        within("#players") do
          charlie_div = find("div[id^='player_']", text: "Charlie")
          within(charlie_div) do
            find("a[title='Edit name']").click
          end
        end

        assert_text "Edit Your Name", wait: 5
        assert_field "Your Name", with: "Charlie"

        # Try to change name to something too short
        fill_in "Your Name", with: "Ch"
        click_on "Update Name"

        # Should see validation error
        assert_text "is too short", wait: 5
        assert_field "Your Name", with: "Ch"

        # Try to change name to match Alice (with emoji - still caught)
        fill_in "Your Name", with: "alice 🎉"
        click_on "Update Name"

        # Should see validation error
        assert_text "has already been taken", wait: 5
        assert_field "Your Name", with: "alice 🎉"

        # Change name successfully
        fill_in "Your Name", with: "Dave"
        click_on "Update Name"

        # Should be redirected back to game
        assert_text "Who would win in an eating contest?", wait: 5
        assert_no_text "Edit Your Name"

        # Verify name was updated
        within("#players") do
          assert_selector "span.fw-bold", text: "Dave"
          assert_no_text "Charlie"
        end
      end

      # Verify others see the name change
      using_session("default") do
        within("#players") do
          assert_selector "span", text: "Dave", wait: 5
          assert_no_text "Charlie"
        end
      end

      using_session("bob") do
        within("#players") do
          assert_selector "span", text: "Dave", wait: 5
          assert_no_text "Charlie"
        end
      end
    end

    test "players can edit their names with validation and broadcasts" do
      # Create a new game with Bob as judge
      visit new_burn_unit_game_path

      fill_in "Your Name", with: "Bob"
      fill_in "First Question", with: "Who would survive on a deserted island?"
      click_on "Create New Game"

      assert_text "Bob"
      game_id = current_path.split("/").last

      # Charlie joins the game
      using_session("charlie") do
        visit new_burn_unit_game_player_path(game_id)
        fill_in "Name", with: "Charlie"
        click_on "Join Game"
        assert_text "Charlie"
      end

      # Zoe joins the game
      using_session("zoe") do
        visit new_burn_unit_game_player_path(game_id)
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
        assert_text "Who would survive on a deserted island?", wait: 5
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

        # Verify vote dropdown has updated names (Alice can vote for Bob or Zoe)
        within("select") do
          options = all("option").map(&:text)
          assert_includes options, "Bob"
          assert_includes options, "Zoe"
          assert_not_includes options, "Alice"
          assert_not_includes options, "Charlie" # Old name should be gone
        end
      end

      # Verify Bob sees the updated player list via broadcast
      using_session("default") do
        within("#players") do
          # Wait for Alice to appear via broadcast
          assert_selector "span", text: "Alice", wait: 5
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

        # Verify Bob's vote dropdown has updated names
        within("select") do
          options = all("option").map(&:text)
          assert_includes options, "Alice"
          assert_includes options, "Zoe"
          assert_not_includes options, "Bob"
          assert_not_includes options, "Charlie" # Old name should be gone
        end
      end

      # Verify Zoe sees the updated player list via broadcast
      using_session("zoe") do
        within("#players") do
          # Wait for Alice to appear via broadcast
          assert_selector "span", text: "Alice", wait: 5
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

        # Verify Zoe's vote dropdown has updated names
        within("select") do
          options = all("option").map(&:text)
          assert_includes options, "Alice"
          assert_includes options, "Bob"
          assert_not_includes options, "Zoe"
          assert_not_includes options, "Charlie" # Old name should be gone
        end
      end

      # Now have everyone vote and complete the round to test completed page
      # Alice votes for Zoe
      using_session("charlie") do
        select "Zoe", from: "player[candidate_id]"
        click_on "Submit Vote"
        sleep 0.5
      end

      # Zoe votes for Alice
      using_session("zoe") do
        select "Alice", from: "player[candidate_id]"
        click_on "Submit Vote"
        sleep 0.5
      end

      # Bob (judge) votes for Alice and tallies
      using_session("default") do
        select "Alice", from: "player[candidate_id]"
        click_on "Submit Vote"
        sleep 0.5

        # Wait for all votes to be visible
        within("#players") do
          assert_selector "i.bi-check-square-fill", count: 3, wait: 5
        end

        click_on "Tally Votes"
        within("dialog[open]") do
          click_on "Yes, tally votes"
        end

        assert_text "Results", wait: 5
      end

      # Verify all sessions see the completed page
      using_session("charlie") do
        assert_text "Results", wait: 5
      end

      using_session("zoe") do
        assert_text "Results", wait: 5
      end

      # Zoe changes her name to Mia on the completed page
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
        assert_text "Results", wait: 5

        # Verify player list shows Mia (still sorted alphabetically)
        within("#players") do
          assert_selector "span.fw-bold", text: "Mia"
          assert_no_text "Zoe"
        end

        # Verify candidates list shows Mia in BOTH places:
        # 1. As a candidate name (Alice got 2 votes, Mia got 1 vote)
        # 2. As a voter name (Mia voted for Alice)
        # Note: Order is by vote count, NOT alphabetical, so doesn't re-sort
        within("#candidates") do
          candidates = all(".list-group-item")

          # First candidate should be Alice (winner, 2 votes from Bob and Mia)
          within(candidates[0]) do
            assert_text "Alice"
            assert_text "2 votes"
            # Voters should show Mia (not Zoe)
            assert_text "Mia"
            assert_no_text "Zoe"
          end

          # Second candidate should be Mia (1 vote from Alice)
          within(candidates[1]) do
            assert_text "Mia"
            assert_text "1 vote"
            assert_no_text "Zoe"
          end
        end
      end

      # Verify Bob sees the name change on completed page via broadcast
      using_session("default") do
        within("#players") do
          assert_selector "span", text: "Mia", wait: 5
          assert_no_text "Zoe"
        end

        # Verify candidates list shows Mia in both places
        within("#candidates") do
          candidates = all(".list-group-item")

          # First candidate should be Alice with Mia as voter
          within(candidates[0]) do
            assert_text "Alice"
            assert_text "Mia"
            assert_no_text "Zoe"
          end

          # Second candidate should be Mia
          within(candidates[1]) do
            assert_text "Mia"
            assert_no_text "Zoe"
          end
        end
      end

      # Verify Alice sees the name change on completed page via broadcast
      using_session("charlie") do
        within("#players") do
          assert_selector "span", text: "Mia", wait: 5
          assert_no_text "Zoe"
        end

        # Verify candidates list shows Mia in both places
        within("#candidates") do
          candidates = all(".list-group-item")

          # First candidate should be Alice with Mia as voter
          within(candidates[0]) do
            assert_text "Alice"
            assert_text "Mia"
            assert_no_text "Zoe"
          end

          # Second candidate should be Mia
          within(candidates[1]) do
            assert_text "Mia"
            assert_no_text "Zoe"
          end
        end
      end
    end
  end
end
