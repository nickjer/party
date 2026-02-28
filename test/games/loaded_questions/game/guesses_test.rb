# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class Game
    class GuessesTest < ActiveSupport::TestCase
      test "#find raises error when player not found" do
        game = build(:lq_matching_game, player_names: %w[Alice Bob])

        error = assert_raises(RuntimeError) { game.guesses.find("nonexistent") }

        assert_equal "Couldn't find guessed answer for player nonexistent",
          error.message
      end

      test "#find returns guessed answer for player" do
        game = build(:lq_matching_game, player_names: %w[Alice Bob])
        non_guesser = game.players.reject(&:guesser?).first

        result = game.guesses.find(non_guesser.id)

        assert_equal non_guesser.id, result.player.id
      end

      test "#initialize raises error when duplicate guessed player found" do
        game = build(:lq_matching_game, player_names: %w[Alice Bob])
        player1, player2 = game.players.reject(&:guesser?)

        guesses = [
          Game::GuessedAnswer.new(player: player1, guessed_player: player1),
          Game::GuessedAnswer.new(player: player2, guessed_player: player1)
        ]

        error = assert_raises(RuntimeError) do
          Game::Guesses.new(guesses:)
        end

        assert_equal "Duplicate guessed player found in guesses", error.message
      end

      test "#initialize raises error when duplicate player found" do
        game = build(:lq_matching_game, player_names: %w[Alice Bob])
        player1, player2 = game.players.reject(&:guesser?)

        guesses = [
          Game::GuessedAnswer.new(player: player1, guessed_player: player1),
          Game::GuessedAnswer.new(player: player1, guessed_player: player2)
        ]

        error = assert_raises(RuntimeError) do
          Game::Guesses.new(guesses:)
        end

        assert_equal "Duplicate player found in guesses", error.message
      end

      test "#assign assigns answer to player slot" do
        game = build(:lq_matching_game, player_names: %w[Alice Bob])
        alice, bob = game.guesses.map(&:player)

        new_guesses = game.guesses.assign(player_id: alice.id,
          answer_id: bob.answer.id)

        alice_guess = new_guesses.find(alice.id)
        assert_equal bob.answer, alice_guess.guessed_answer
      end

      test "#assign with nil answer_id clears the assignment" do
        game = build(:lq_matching_game, player_names: %w[Alice Bob])
        alice = game.guesses.first.player

        # First assign an answer to Alice
        guesses = game.guesses.assign(player_id: alice.id,
          answer_id: alice.answer.id)

        # Verify Alice has an assigned answer before clearing
        alice_guess_before = guesses.find(alice.id)
        assert_predicate alice_guess_before, :assigned?

        # Now clear the assignment
        new_guesses = guesses.assign(player_id: alice.id, answer_id: nil)

        alice_guess = new_guesses.find(alice.id)
        assert_not_predicate alice_guess, :assigned?
      end

      test "#for_completed_view attributes each player's answer to " \
        "who the guesser placed it with" do
        game = build(:lq_matching_game, players: [
          { name: "Alice", answer: "Pizza" },
          { name: "Bob", answer: "Cats" },
          { name: "Charlie", answer: "Dogs" }
        ])

        alice, bob, charlie =
          game.guesses.map(&:player).sort_by(&:name)

        # 3-cycle: Bob's "Cats" → Alice's slot, Charlie's "Dogs" → Bob's slot,
        #          Alice's "Pizza" → Charlie's slot
        game.assign_guess(player_id: alice.id, answer_id: bob.answer.id)
        game.assign_guess(player_id: bob.id, answer_id: charlie.answer.id)
        game.assign_guess(player_id: charlie.id, answer_id: alice.answer.id)

        results =
          game.guesses.for_completed_view.index_by { |result| result.player.id }

        # Alice's "Pizza" landed in Charlie's slot, so attributed_to is Charlie
        assert_equal charlie.id, results[alice.id].attributed_to.id
        assert_equal alice.id,   results[bob.id].attributed_to.id
        assert_equal bob.id,     results[charlie.id].attributed_to.id
      end

      test "#assign clears previous assignment when answer is reassigned" do
        game = build(:lq_matching_game, player_names: %w[Alice Bob])
        alice, bob = game.guesses.map(&:player)

        # First assign Bob's answer to Alice
        guesses = game.guesses.assign(player_id: alice.id,
          answer_id: bob.answer.id)
        # Then assign Bob's answer to Bob (should clear Alice's assignment)
        guesses = guesses.assign(player_id: bob.id, answer_id: bob.answer.id)

        alice_guess = guesses.find(alice.id)
        bob_guess = guesses.find(bob.id)

        assert_not_predicate alice_guess, :assigned?
        assert_equal bob.answer, bob_guess.guessed_answer
      end
    end
  end
end
