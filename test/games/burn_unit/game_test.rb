# frozen_string_literal: true

require "test_helper"

module BurnUnit
  class GameTest < ActiveSupport::TestCase
    test ".build creates game with question" do
      question = NormalizedString.new("What is your favorite color?")
      game = Game.build(question:)

      assert_equal "What is your favorite color?", game.question.to_s
      assert_predicate game.status, :polling?
    end

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
      game = build(:bu_game)

      player = game.add_player(user_id: user.id,
        name: NormalizedString.new("Alice"))

      assert_equal user.id, player.user_id
      assert_equal "Alice", player.name.to_s
      assert_not_predicate player, :judge?
      assert_not_predicate player, :playing?
      assert_includes game.players, player
    end

    test "#add_player creates judge when judge: true" do
      user = build(:user)
      question = NormalizedString.new("What is your favorite color?")
      game = Game.build(question:)
      player = game.add_player(user_id: user.id,
        name: NormalizedString.new("Alice"), judge: true, playing: true)

      assert_predicate player, :judge?
      assert_equal player, game.judge
    end

    test "#add_player maintains alphabetical sort order" do
      game = build(:bu_polling_game, player_names: %w[Alice Charlie],
        judge_name: "David")
      user = build(:user)

      game.add_player(user_id: user.id, name: NormalizedString.new("Bob"))

      player_names = game.players.map(&:name).map(&:to_s)
      assert_equal %w[Alice Bob Charlie David], player_names
    end

    test "#add_player persists player after save" do
      user = create(:user)
      game = create(:bu_game)

      player = game.add_player(user_id: user.id,
        name: NormalizedString.new("Alice"))
      game.save!

      game_after = reload(game:)
      reloaded_player = game_after.player_for(user.id)

      assert_not_nil reloaded_player
      assert_equal player.id, reloaded_player.id
      assert_equal "Alice", reloaded_player.name.to_s
    end

    test "#add_player raises error when player already exists for user" do
      game = build(:bu_polling_game, player_names: %w[Alice])
      existing_player = game.players.first
      user_id = existing_player.user_id

      error = assert_raises(RuntimeError) do
        game.add_player(user_id:, name: NormalizedString.new("Bob"))
      end

      assert_equal "Player already exists for user", error.message
    end

    test "#candidates returns only playing players as Candidate objects" do
      game = build(:bu_polling_game,
        judge_name: "Judge",
        players: [
          { name: "Alice", not_playing: true },
          { name: "Bob" },
          { name: "Charlie" }
        ])

      candidates = game.candidates

      assert_equal 3, candidates.size
      assert(candidates.all? { |c| c.is_a?(Game::Candidate) })
      candidate_names = candidates.map { |c| c.player.name.to_s }
      assert_equal %w[Bob Charlie Judge], candidate_names
    end

    test "#candidates with votes returns candidates sorted by vote count" do
      game = build(:bu_polling_game,
        judge_name: "Judge",
        players: [
          { name: "Alice", vote_for: "Bob" },
          { name: "Bob", vote_for: "Bob" },
          { name: "Charlie", vote_for: "Alice" }
        ])

      candidates = game.candidates

      # Bob should be first (2 votes), Alice second (1 vote), others last
      assert_equal "Bob", candidates.first.player.name.to_s
      assert_equal 2, candidates.first.voters.size
      assert_predicate candidates.first, :winner?
    end

    test "#judge returns the judge player" do
      game = build(:bu_polling_game, judge_name: "Alice",
        player_names: %w[Bob Charlie])

      judge = game.judge

      assert_not_nil judge
      assert_equal "Alice", judge.name.to_s
      assert_predicate judge, :judge?
    end

    test "#player_for returns nil when user has no player" do
      game = build(:bu_polling_game)
      non_existent_user = build(:user)

      player = game.player_for(non_existent_user.id)

      assert_nil player
    end

    test "#player_for returns player for given user_id" do
      user = build(:user)
      game = build(:bu_game)
      game.add_player(user_id: user.id, name: NormalizedString.new("Alice"))

      player = game.player_for(user.id)

      assert_not_nil player
      assert_equal "Alice", player.name.to_s
    end

    test "#player_for! returns player for given user_id" do
      user = build(:user)
      game = build(:bu_game)
      game.add_player(user_id: user.id, name: NormalizedString.new("Alice"))

      player = game.player_for!(user.id)

      assert_not_nil player
      assert_equal "Alice", player.name.to_s
    end

    test "#player_for! raises RecordNotFound when user has no player" do
      game = build(:bu_polling_game)
      non_existent_user = build(:user)

      error = assert_raises(ActiveRecord::RecordNotFound) do
        game.player_for!(non_existent_user.id)
      end

      assert_equal "Couldn't find Player", error.message
    end

    test "#players returns dynamically sorted players after name change" do
      game = build(:bu_polling_game, player_names: %w[Bob Charlie],
        judge_name: "Alice")

      player_names = game.players.map(&:name).map(&:to_s)
      assert_equal %w[Alice Bob Charlie], player_names

      # Update a player's name without saving
      alice = game.players.first
      alice.name = NormalizedString.new("Zoe")

      # Verify players are still sorted dynamically
      player_names_after = game.players.map(&:name).map(&:to_s)
      assert_equal %w[Bob Charlie Zoe], player_names_after
    end

    test "#question= persists to database after save" do
      game = create(:bu_game)
      new_question = NormalizedString.new("What is your favorite animal?")

      game.question = new_question
      game.save!

      reloaded_game = reload(game:)

      assert_equal "What is your favorite animal?", reloaded_game.question.to_s
    end

    test "#question= raises error when question is too long" do
      game = build(:bu_game)
      long_question = NormalizedString.new("a" * 161)

      error = assert_raises(ArgumentError) do
        game.question = long_question
      end

      assert_match(/Question length must be between 3 and 160 characters/,
        error.message)
    end

    test "#question= raises error when question is too short" do
      game = build(:bu_game)
      short_question = NormalizedString.new("AB")

      error = assert_raises(ArgumentError) do
        game.question = short_question
      end

      assert_match(/Question length must be between 3 and 160 characters/,
        error.message)
    end

    test "#status= persists to database after save" do
      game = create(:bu_game)

      assert_predicate game.status, :polling?

      game.status = Game::Status.completed
      game.save!

      reloaded_game = reload(game:)

      assert_predicate reloaded_game.status, :completed?
    end
  end
end
