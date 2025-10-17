# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class GameTest < ActiveSupport::TestCase
    test "swap_guesses persists answer swap to database" do
      # Create a game with guesser and two players
      game = create(:loaded_questions_game, players: %w[Bob Charlie])

      # Get players and submit answers
      bob = game.players.find { |p| p.name.to_s == "Bob" }
      charlie = game.players.find { |p| p.name.to_s == "Charlie" }

      bob.update_answer(NormalizedString.new("Blue"))
      charlie.update_answer(NormalizedString.new("Red"))

      # Start guessing round to shuffle answers
      game = Game.find(game.slug)
      game.update_status(Game::Status.guessing)

      # Reload and get current answer assignments
      game = Game.find(game.slug)
      guess1, guess2 = game.guesses.to_a
      guess1_guessed_answer_before = guess1.guessed_answer
      guess2_guessed_answer_before = guess2.guessed_answer

      # Swap the answers
      game.swap_guesses(player_id1: guess1.player.id,
        player_id2: guess2.player.id)

      # Reload from database to verify persistence
      game_after = Game.find(game.slug)
      guess1_after, guess2_after = game_after.guesses.to_a

      # Verify answers were swapped and persisted
      assert_equal guess2_guessed_answer_before, guess1_after.guessed_answer,
        "First guess should have second guessed answer after swap"
      assert_equal guess1_guessed_answer_before, guess2_after.guessed_answer,
        "Second guess should have first guessed answer after swap"
    end
  end
end
