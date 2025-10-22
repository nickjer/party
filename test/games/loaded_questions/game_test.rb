# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class GameTest < ActiveSupport::TestCase
    test ".build raises error when question is too short" do
      short_question = NormalizedString.new("AB")

      error = assert_raises(ArgumentError) do
        Game.build(question: short_question)
      end

      assert_match(/Question length must be between 3 and 160 characters/,
        error.message)
    end

    test "swap_guesses persists answer swap to database" do
      # Create game in guessing status with players and answers
      game = create(:lq_matching_game, player_names: %w[Bob Charlie])

      # Get current answer assignments
      guess1, guess2 = game.guesses.to_a
      guess1_guessed_answer_before = guess1.guessed_answer
      guess2_guessed_answer_before = guess2.guessed_answer

      # Swap the answers
      game.swap_guesses(player_id1: guess1.player.id,
        player_id2: guess2.player.id)
      game.save!

      # Reload from database to verify persistence
      game_after = reload(game:)
      guess1_after, guess2_after = game_after.guesses.to_a

      # Verify answers were swapped and persisted
      assert_equal guess2_guessed_answer_before, guess1_after.guessed_answer,
        "First guess should have second guessed answer after swap"
      assert_equal guess1_guessed_answer_before, guess2_after.guessed_answer,
        "Second guess should have first guessed answer after swap"
    end

    test "#add_player creates and adds player to game" do
      user = build(:user)
      game = build(:lq_game)

      player = game.add_player(user_id: user.id,
        name: NormalizedString.new("Alice"))

      assert_equal user.id, player.user_id
      assert_equal "Alice", player.name.to_s
      assert_not_predicate player, :guesser?
      assert_includes game.players, player
    end

    test "#add_player creates guesser when guesser: true" do
      user = build(:user)
      question = NormalizedString.new("What is your favorite color?")
      game = Game.build(question:)
      player = game.add_player(user_id: user.id,
        name: NormalizedString.new("Alice"), guesser: true)

      assert_predicate player, :guesser?
      assert_equal player, game.guesser
    end

    test "#add_player raises error when called twice for same user_id" do
      user = build(:user)
      game = build(:lq_game)

      game.add_player(user_id: user.id, name: NormalizedString.new("Alice"))

      error = assert_raises(RuntimeError) do
        game.add_player(user_id: user.id, name: NormalizedString.new("Bob"))
      end

      assert_equal "Player already exists for user", error.message
    end

    test "#add_player raises error when player already exists for user" do
      game = build(:lq_polling_game, player_names: %w[Alice])
      existing_player = game.players.first
      user_id = existing_player.user_id

      error = assert_raises(RuntimeError) do
        game.add_player(user_id:, name: NormalizedString.new("Bob"))
      end

      assert_equal "Player already exists for user", error.message
    end

    test "#add_player persists player after save" do
      user = create(:user)
      game = create(:lq_game)

      player = game.add_player(user_id: user.id,
        name: NormalizedString.new("Alice"))
      game.save!

      game_after = reload(game:)
      reloaded_player = game_after.player_for(user.id)

      assert_not_nil reloaded_player
      assert_equal player.id, reloaded_player.id
      assert_equal "Alice", reloaded_player.name.to_s
    end

    test "#add_player maintains alphabetical sort order" do
      game = build(:lq_polling_game, player_names: %w[Alice Charlie],
        guesser_name: "David")
      user = build(:user)

      game.add_player(user_id: user.id, name: NormalizedString.new("Bob"))

      player_names = game.players.map(&:name).map(&:to_s)
      assert_equal %w[Alice Bob Charlie David], player_names
    end

    test "#players returns dynamically sorted players after name change" do
      game = build(:lq_polling_game, player_names: %w[Bob Charlie],
        guesser_name: "Alice")

      player_names = game.players.map(&:name).map(&:to_s)
      assert_equal %w[Alice Bob Charlie], player_names

      # Update a player's name without saving
      alice = game.players.first
      alice.name = NormalizedString.new("Zoe")

      # Verify players are still sorted dynamically
      player_names_after = game.players.map(&:name).map(&:to_s)
      assert_equal %w[Bob Charlie Zoe], player_names_after
    end
  end
end
