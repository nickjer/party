require "test_helper"

module LoadedQuestions
  class GameTest < ActiveSupport::TestCase
    test "swap_guesses persists answer swap to database" do
      # Create a game with guesser and two players
      game = create(:loaded_questions_game, players: [ "Bob", "Charlie" ])

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
      bob = game.players.find { |p| p.name.to_s == "Bob" }
      charlie = game.players.find { |p| p.name.to_s == "Charlie" }

      bob_answer_before = game.guesses.find(bob.id).answer
      charlie_answer_before = game.guesses.find(charlie.id).answer

      # Swap the answers
      game.swap_guesses(player_id_1: bob.id, player_id_2: charlie.id)

      # Reload from database to verify persistence
      game_after = Game.find(game.slug)
      bob_answer_after = game_after.guesses.find(bob.id).answer
      charlie_answer_after = game_after.guesses.find(charlie.id).answer

      # Verify answers were swapped and persisted
      assert_equal charlie_answer_before, bob_answer_after, "Bob should have Charlie's answer after swap"
      assert_equal bob_answer_before, charlie_answer_after, "Charlie should have Bob's answer after swap"
    end
  end
end
