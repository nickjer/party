require "test_helper"

module LoadedQuestions
  class GameTest < ActiveSupport::TestCase
    test "swap_guesses persists answer swap to database" do
      # Create a game with guesser
      user1 = User.create!(last_seen_at: Time.current)
      game = NewGame.new(
        user: user1,
        player_name: NormalizedString.new("Alice"),
        question: NormalizedString.new("What is your favorite color?")
      ).build
      game.save!

      loaded_game = Game.find(game.slug)

      # Add two players with answers
      user2 = User.create!(last_seen_at: Time.current)
      player2 = NewPlayer.new(user: user2, name: NormalizedString.new("Bob"), guesser: false).build
      player2.game_id = game.id
      player2.save!

      user3 = User.create!(last_seen_at: Time.current)
      player3 = NewPlayer.new(user: user3, name: NormalizedString.new("Charlie"), guesser: false).build
      player3.game_id = game.id
      player3.save!

      # Submit answers
      loaded_game = Game.find(game.slug)
      bob = loaded_game.players.find { |p| p.name.to_s == "Bob" }
      charlie = loaded_game.players.find { |p| p.name.to_s == "Charlie" }

      bob.update_answer(NormalizedString.new("Blue"))
      charlie.update_answer(NormalizedString.new("Red"))

      # Start guessing round to shuffle answers
      loaded_game = Game.find(game.slug)
      loaded_game.update_status(Game::Status.guessing)

      # Reload and get current answer assignments
      loaded_game = Game.find(game.slug)
      bob = loaded_game.players.find { |p| p.name.to_s == "Bob" }
      charlie = loaded_game.players.find { |p| p.name.to_s == "Charlie" }

      bob_answer_before = loaded_game.guesses.find(bob.id).answer
      charlie_answer_before = loaded_game.guesses.find(charlie.id).answer

      # Swap the answers
      loaded_game.swap_guesses(player_id_1: bob.id, player_id_2: charlie.id)

      # Reload from database to verify persistence
      loaded_game_after = Game.find(game.slug)
      bob_answer_after = loaded_game_after.guesses.find(bob.id).answer
      charlie_answer_after = loaded_game_after.guesses.find(charlie.id).answer

      # Verify answers were swapped and persisted
      assert_equal charlie_answer_before, bob_answer_after, "Bob should have Charlie's answer after swap"
      assert_equal bob_answer_before, charlie_answer_after, "Charlie should have Bob's answer after swap"
    end
  end
end
