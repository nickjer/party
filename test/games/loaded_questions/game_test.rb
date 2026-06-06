# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class GameTest < ActiveSupport::TestCase
    test ".build raises error when question is too long" do
      long_question = NormalizedString.new("a" * 161)

      error = assert_raises(ArgumentError) do
        Game.build(question: long_question)
      end

      assert_match(/Question length must be between 3 and 160 characters/,
        error.message)
    end

    test ".build raises error when question is too short" do
      short_question = NormalizedString.new("AB")

      error = assert_raises(ArgumentError) do
        Game.build(question: short_question)
      end

      assert_match(/Question length must be between 3 and 160 characters/,
        error.message)
    end

    test "#add_player creates and adds player to game" do
      user = build(:user)
      game = build(:lq_game)

      player = game.add_player(user_id: user.id,
        name: PlayerName.parse("Alice"))

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
        name: PlayerName.parse("Alice"), guesser: true)

      assert_predicate player, :guesser?
      assert_equal player, game.guesser
    end

    test "#add_player maintains alphabetical sort order" do
      game = build(:lq_polling_game, player_names: %w[Alice Charlie],
        guesser_name: "David")
      user = build(:user)

      game.add_player(user_id: user.id, name: PlayerName.parse("Bob"))

      player_names = game.players.map(&:name).map(&:to_s)
      assert_equal %w[Alice Bob Charlie David], player_names
    end

    test "#add_player persists player after save" do
      user = create(:user)
      game = create(:lq_game)

      player = game.add_player(user_id: user.id,
        name: PlayerName.parse("Alice"))
      GameRepo.save(game)

      game_after = reload(game:)
      reloaded_player = game_after.player_for(user.id)

      assert_not_nil reloaded_player
      assert_equal player.id, reloaded_player.id
      assert_equal "Alice", reloaded_player.name.to_s
    end

    test "#add_player raises error when called twice for same user_id" do
      user = build(:user)
      game = build(:lq_game)

      game.add_player(user_id: user.id, name: PlayerName.parse("Alice"))

      error = assert_raises(RuntimeError) do
        game.add_player(user_id: user.id, name: PlayerName.parse("Bob"))
      end

      assert_equal "Player already exists for user", error.message
    end

    test "#add_player raises error when player already exists for user" do
      game = build(:lq_polling_game, player_names: %w[Alice])
      existing_player = game.players.first
      user_id = existing_player.user_id

      error = assert_raises(RuntimeError) do
        game.add_player(user_id:, name: PlayerName.parse("Bob"))
      end

      assert_equal "Player already exists for user", error.message
    end

    test "#players returns dynamically sorted players after name change" do
      game = build(:lq_polling_game, player_names: %w[Bob Charlie],
        guesser_name: "Alice")

      player_names = game.players.map(&:name).map(&:to_s)
      assert_equal %w[Alice Bob Charlie], player_names

      # Update a player's name without saving
      alice = game.players.first
      alice.name = PlayerName.parse("Zoe")

      # Verify players are still sorted dynamically
      player_names_after = game.players.map(&:name).map(&:to_s)
      assert_equal %w[Bob Charlie Zoe], player_names_after
    end

    test "#assign_guess persists answer assignment to database" do
      # Create game in guessing status with players and answers
      game = create(:lq_matching_game, player_names: %w[Bob Charlie])

      # Get players and their answers
      bob, charlie = game.guesses.map(&:player)

      # Assign Bob's answer to Charlie's slot
      game.assign_guess(player_id: charlie.id, answer_id: bob.answer.id)
      GameRepo.save(game)

      # Reload from database to verify persistence
      game_after = reload(game:)
      charlie_guess = game_after.guesses.find(charlie.id)

      # Verify assignment was persisted
      assert_equal bob.answer, charlie_guess.guessed_answer,
        "Charlie's slot should have Bob's answer assigned"
    end

    test "#begin_guessing creates guess pairs from answered players" do
      game = build(:lq_polling_game, players: [
        { name: "Alice", answer: "Blue" },
        { name: "Bob", answer: "Red" },
        { name: "Charlie", answer: "" }
      ])

      game.begin_guessing

      assert_equal 2, game.guesses.size

      answered_players = game.players.select(&:answered?)
      answered_players.each do |player|
        guess = game.guesses.find(player.id)

        assert_not_nil guess
        assert_equal player.id, guess.player.id
      end
    end

    test "#begin_guessing raises error when game is not in polling status" do
      game = build(:lq_matching_game, player_names: %w[Alice Bob])

      assert_predicate game.status, :guessing?

      error = assert_raises(RuntimeError) { game.begin_guessing }

      assert_equal "Game must be in polling status", error.message
    end

    test "#begin_guessing returns the game" do
      game = build(:lq_polling_game, players: [
        { name: "Alice", answer: "Blue" },
        { name: "Bob", answer: "Red" }
      ])

      assert_equal game, game.begin_guessing
    end

    test "#begin_guessing transitions game from polling to guessing status" do
      game = build(:lq_polling_game, players: [
        { name: "Alice", answer: "Blue" },
        { name: "Bob", answer: "Red" }
      ])

      assert_predicate game.status, :polling?

      game.begin_guessing

      assert_predicate game.status, :guessing?
    end

    test "#begin_guessing persists changes after save" do
      game = create(:lq_polling_game, players: [
        { name: "Alice", answer: "Blue" },
        { name: "Bob", answer: "Red" }
      ])

      game.begin_guessing
      GameRepo.save(game)

      reloaded_game = reload(game:)

      assert_predicate reloaded_game.status, :guessing?
      assert_equal 2, reloaded_game.guesses.size
    end

    test "#complete_round adds to existing guesser score" do
      game = build(:lq_matching_game, player_names: %w[Alice Bob Charlie])
      guesser = game.guesser
      guesser.score = 5

      # Make one guess correct, swap the other two
      player1, player2, player3 = game.players.reject(&:guesser?)
      game.assign_guess(player_id: player1.id, answer_id: player1.answer.id)
      game.assign_guess(player_id: player2.id, answer_id: player3.answer.id)
      game.assign_guess(player_id: player3.id, answer_id: player2.answer.id)

      assert_equal 1, game.guesses.score

      game.complete_round

      assert_equal 6, game.guesser.score
    end

    test "#complete_round raises error when game is not in guessing status" do
      game = build(:lq_polling_game, player_names: %w[Alice Bob])

      assert_predicate game.status, :polling?

      error = assert_raises(RuntimeError) { game.complete_round }

      assert_equal "Game must be in guessing status", error.message
    end

    test "#complete_round returns the game" do
      game = build(:lq_matching_game, player_names: %w[Alice Bob])

      assert_equal game, game.complete_round
    end

    test "#complete_round transitions game from guessing to completed status" do
      game = build(:lq_matching_game, player_names: %w[Alice Bob])

      assert_predicate game.status, :guessing?

      game.complete_round

      assert_predicate game.status, :completed?
    end

    test "#complete_round updates guesser score with correct guess count" do
      game = build(:lq_matching_game, player_names: %w[Alice Bob])
      guesser = game.guesser

      assert_equal 0, guesser.score

      # Make all guesses correct
      game.guesses.each do |guess|
        game.assign_guess(player_id: guess.player.id,
          answer_id: guess.player.answer.id)
      end

      assert_equal 2, game.guesses.score

      game.complete_round

      assert_equal 2, game.guesser.score
    end

    test "#start_new_round persists changes after save" do
      game = create(:lq_completed_game, player_names: %w[Alice Bob])
      new_guesser = game.players.reject(&:guesser?).first
      new_question = NormalizedString.new("What is your favorite animal?")

      game.start_new_round(question: new_question, guesser: new_guesser)
      GameRepo.save(game)

      reloaded_game = reload(game:)

      assert_equal "What is your favorite animal?", reloaded_game.question.to_s
      assert_predicate reloaded_game.status, :polling?
      assert_predicate reloaded_game.player_for(new_guesser.user_id), :guesser?
    end

    test "#start_new_round raises error when question is too long" do
      game = build(:lq_completed_game, player_names: %w[Alice Bob])
      new_guesser = game.players.reject(&:guesser?).first
      long_question = NormalizedString.new("a" * 161)

      error = assert_raises(ArgumentError) do
        game.start_new_round(question: long_question, guesser: new_guesser)
      end

      assert_match(/Question length must be between 3 and 160 characters/,
        error.message)
    end

    test "#start_new_round raises error when question is too short" do
      game = build(:lq_completed_game, player_names: %w[Alice Bob])
      new_guesser = game.players.reject(&:guesser?).first
      short_question = NormalizedString.new("AB")

      error = assert_raises(ArgumentError) do
        game.start_new_round(question: short_question, guesser: new_guesser)
      end

      assert_match(/Question length must be between 3 and 160 characters/,
        error.message)
    end

    test "#start_new_round raises error when game is not in completed status" do
      game = build(:lq_polling_game, player_names: %w[Alice Bob])
      new_guesser = game.players.reject(&:guesser?).first
      question = NormalizedString.new("What is your favorite animal?")

      assert_predicate game.status, :polling?

      error = assert_raises(RuntimeError) do
        game.start_new_round(question:, guesser: new_guesser)
      end

      assert_equal "Game must be in completed status", error.message
    end

    test "#to_global_id builds a GlobalID for the game" do
      game = build(:lq_game)

      gid = game.to_global_id

      assert_equal "Game", gid.model_name
      assert_equal game.id, gid.model_id
    end
  end
end
