# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class GamesControllerTest < ActionDispatch::IntegrationTest
    test "#swap_guesses persists answer swap to database" do
      # Create a game with guesser
      user1 = User.create!(last_seen_at: Time.current)
      game = NewGame.new(
        user: user1,
        player_name: NormalizedString.new("Alice"),
        question: NormalizedString.new("What is your favorite color?")
      ).build
      game.save!

      Game.from_slug(game.slug)

      # Add two players with answers
      user2 = User.create!(last_seen_at: Time.current)
      player2 = NewPlayer.new(user: user2, name: NormalizedString.new("Bob"),
        guesser: false).build
      player2.game_id = game.id
      player2.save!

      user3 = User.create!(last_seen_at: Time.current)
      player3 = NewPlayer.new(user: user3,
        name: NormalizedString.new("Charlie"), guesser: false).build
      player3.game_id = game.id
      player3.save!

      # Submit answers
      loaded_game = Game.from_slug(game.slug)
      bob = loaded_game.players.find { |p| p.name.to_s == "Bob" }
      charlie = loaded_game.players.find { |p| p.name.to_s == "Charlie" }

      bob.update_answer(NormalizedString.new("Blue"))
      charlie.update_answer(NormalizedString.new("Red"))

      # Start guessing round to shuffle answers
      loaded_game = Game.from_slug(game.slug)
      loaded_game.update_status(LoadedQuestions::Game::Status.guessing)

      # Reload and get current answer assignments
      loaded_game = Game.from_slug(game.slug)
      guess1, guess2 = loaded_game.guesses.to_a
      guess1_guessed_answer_before = guess1.guessed_answer
      guess2_guessed_answer_before = guess2.guessed_answer

      # Swap the answers
      loaded_game.swap_guesses(player_id1: guess1.player.id,
        player_id2: guess2.player.id)

      # Reload from database to verify persistence
      loaded_game_after = Game.from_slug(game.slug)
      guess1_after, guess2_after = loaded_game_after.guesses.to_a

      # Verify answers were swapped and persisted
      assert_equal guess2_guessed_answer_before, guess1_after.guessed_answer,
        "First guess should have second guessed answer after swap"
      assert_equal guess1_guessed_answer_before, guess2_after.guessed_answer,
        "Second guess should have first guessed answer after swap"
    end

    test "#completed_round changes game status from guessing to completed" do
      # Create game with guesser and players
      game = create(:loaded_questions_game, players: %w[Bob Charlie])
      bob = game.players.find { |p| p.name.to_s == "Bob" }
      charlie = game.players.find { |p| p.name.to_s == "Charlie" }

      # Submit answers
      bob.update_answer(NormalizedString.new("Blue"))
      charlie.update_answer(NormalizedString.new("Red"))

      # Transition to guessing phase
      game = LoadedQuestions::Game.from_slug(game.slug)
      game.update_status(LoadedQuestions::Game::Status.guessing)

      # Verify game is in guessing status
      game = LoadedQuestions::Game.from_slug(game.slug)
      assert_predicate game.status, :guessing?

      # Sign in as guesser
      guesser = game.players.find(&:guesser?)
      sign_in(guesser.user)

      # Make request to complete round
      patch completed_round_loaded_questions_game_path(game.slug)

      # Verify redirect
      assert_redirected_to loaded_questions_game_path(game.slug)

      # Reload and verify game status changed to completed
      game = LoadedQuestions::Game.from_slug(game.slug)
      assert_predicate game.status, :completed?
    end

    test "#completed_round returns error when not in guessing phase" do
      # Create game with guesser and players in polling phase
      game = create(:loaded_questions_game, players: %w[Bob Charlie])

      # Verify game is in polling status
      assert_predicate game.status, :polling?

      # Sign in as guesser
      guesser = game.players.find(&:guesser?)
      sign_in(guesser.user)

      # Try to complete round while still in polling phase
      patch completed_round_loaded_questions_game_path(game.slug)

      # Verify unprocessable_content response
      assert_response :unprocessable_content

      # Reload and verify game status has not changed
      game = LoadedQuestions::Game.from_slug(game.slug)
      assert_predicate game.status, :polling?
    end
  end
end
