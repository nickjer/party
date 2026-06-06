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
        name: PlayerName.parse("Alice"))

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
        name: PlayerName.parse("Alice"), judge: true, playing: true)

      assert_predicate player, :judge?
      assert_equal player, game.judge
    end

    test "#add_player maintains alphabetical sort order" do
      game = build(:bu_polling_game, player_names: %w[Alice Charlie],
        judge_name: "David")
      user = build(:user)

      game.add_player(user_id: user.id, name: PlayerName.parse("Bob"))

      player_names = game.players.map(&:name).map(&:to_s)
      assert_equal %w[Alice Bob Charlie David], player_names
    end

    test "#add_player persists player after save" do
      user = create(:user)
      game = create(:bu_game)

      player = game.add_player(user_id: user.id,
        name: PlayerName.parse("Alice"))
      GameRepo.save(game)

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
        game.add_player(user_id:, name: PlayerName.parse("Bob"))
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
      assert(candidates.all?(Game::Candidate))
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
      game.add_player(user_id: user.id, name: PlayerName.parse("Alice"))

      player = game.player_for(user.id)

      assert_not_nil player
      assert_equal "Alice", player.name.to_s
    end

    test "#player_for! returns player for given user_id" do
      user = build(:user)
      game = build(:bu_game)
      game.add_player(user_id: user.id, name: PlayerName.parse("Alice"))

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
      alice.name = PlayerName.parse("Zoe")

      # Verify players are still sorted dynamically
      player_names_after = game.players.map(&:name).map(&:to_s)
      assert_equal %w[Bob Charlie Zoe], player_names_after
    end

    test "#complete_round changes game status from polling to completed" do
      game = build(:bu_polling_game, judge_name: "Alice",
        player_names: %w[Bob])

      assert_predicate game.status, :polling?

      game.complete_round

      assert_predicate game.status, :completed?
    end

    test "#complete_round awards point to single winner" do
      game = build(:bu_polling_game,
        judge_name: "Judge",
        players: [
          { name: "Alice", vote_for: "Bob" },
          { name: "Bob", vote_for: "Charlie" },
          { name: "Charlie", vote_for: "Bob" }
        ])
      bob = game.players.find { |p| p.name.to_s == "Bob" }
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      charlie = game.players.find { |p| p.name.to_s == "Charlie" }
      judge = game.judge

      assert_equal 0, bob.score

      game.complete_round

      # Bob has 2 votes (from Alice and Charlie), everyone else has fewer
      assert_equal 1, bob.score
      assert_equal 0, alice.score
      assert_equal 0, charlie.score
      assert_equal 0, judge.score
    end

    test "#complete_round awards points to multiple winners when tied" do
      game = build(:bu_polling_game,
        judge_name: "Judge",
        players: [
          { name: "Alice", vote_for: "Bob" },
          { name: "Bob", vote_for: "Alice" },
          { name: "Charlie", vote_for: "Judge" }
        ])
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      bob = game.players.find { |p| p.name.to_s == "Bob" }
      charlie = game.players.find { |p| p.name.to_s == "Charlie" }
      judge = game.judge

      game.complete_round

      # Alice, Bob, and Judge all have 1 vote - all tied for winner
      assert_equal 1, alice.score
      assert_equal 1, bob.score
      assert_equal 0, charlie.score
      assert_equal 1, judge.score
    end

    test "#complete_round awards no points when no one has votes" do
      game = build(:bu_polling_game, judge_name: "Judge",
        player_names: %w[Alice Bob Charlie])

      game.complete_round

      game.players.each do |player|
        assert_equal 0, player.score
      end
    end

    test "#complete_round preserves existing scores" do
      game = build(:bu_polling_game,
        judge_name: "Judge",
        players: [
          { name: "Alice", vote_for: "Bob" },
          { name: "Bob", vote_for: "Alice" }
        ])
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      bob = game.players.find { |p| p.name.to_s == "Bob" }
      judge = game.judge

      # Set initial scores
      alice.score = 5
      bob.score = 3
      judge.score = 2

      game.complete_round

      # Alice and Bob tied with 1 vote each, so both get +1
      assert_equal 6, alice.score
      assert_equal 4, bob.score
      assert_equal 2, judge.score
    end

    test "#complete_round returns the game" do
      game = build(:bu_polling_game, judge_name: "Alice",
        player_names: %w[Bob])

      assert_equal game, game.complete_round
    end

    test "#complete_round persists changes after save" do
      game = create(:bu_polling_game,
        judge_name: "Judge",
        players: [
          { name: "Alice", vote_for: "Bob" },
          { name: "Bob", vote_for: "Alice" }
        ])
      bob_id = game.players.find { |p| p.name.to_s == "Bob" }.id
      alice_id = game.players.find { |p| p.name.to_s == "Alice" }.id

      game.complete_round
      GameRepo.save(game)

      reloaded_game = GameRepo.find(game.id)
      assert_predicate reloaded_game.status, :completed?

      bob = reloaded_game.players.find { |p| p.id == bob_id }
      alice = reloaded_game.players.find { |p| p.id == alice_id }
      assert_equal 1, bob.score
      assert_equal 1, alice.score
    end

    test "#complete_round raises error when game is not in polling status" do
      game = build(:bu_completed_game, judge_name: "Alice",
        player_names: %w[Bob])

      assert_predicate game.status, :completed?

      error = assert_raises(RuntimeError) { game.complete_round }

      assert_equal "Game must be in polling status", error.message
    end

    test "#complete_round only awards points to playing players" do
      game = build(:bu_polling_game,
        judge_name: "Judge",
        players: [
          { name: "Alice", vote_for: "Bob", not_playing: true },
          { name: "Bob", vote_for: "Judge" },
          { name: "Charlie", vote_for: "Judge" }
        ])
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      bob = game.players.find { |p| p.name.to_s == "Bob" }
      charlie = game.players.find { |p| p.name.to_s == "Charlie" }
      judge = game.judge

      assert_not_predicate alice, :playing?
      assert_predicate judge, :playing?

      game.complete_round

      # Judge has 2 votes and is the only winner
      # Alice is not playing so doesn't count as a candidate
      assert_equal 0, alice.score
      assert_equal 0, bob.score
      assert_equal 0, charlie.score
      assert_equal 1, judge.score
    end

    test "#start_new_round updates game with new question and polling status" do
      game = build(:bu_completed_game, player_names: %w[Alice Bob],
        judge_name: "Charlie")
      new_judge = game.players.find { |p| p.name.to_s == "Alice" }
      question = NormalizedString.new("What is your favorite animal?")

      game.start_new_round(question:, judge: new_judge)

      assert_equal "What is your favorite animal?", game.question.to_s
      assert_predicate game.status, :polling?
    end

    test "#start_new_round sets new judge correctly" do
      game = build(:bu_completed_game, player_names: %w[Alice Bob],
        judge_name: "Charlie")
      new_judge = game.players.find { |p| p.name.to_s == "Alice" }
      question = NormalizedString.new("What is your favorite animal?")

      game.start_new_round(question:, judge: new_judge)

      assert_equal new_judge, game.judge
      assert_predicate new_judge, :judge?
      game.players.reject { |p| p == new_judge }.each do |player|
        assert_not_predicate player, :judge?
      end
    end

    test "#start_new_round clears all player votes" do
      game = build(:bu_completed_game,
        judge_name: "Judge",
        players: [
          { name: "Alice", vote_for: "Bob" },
          { name: "Bob", vote_for: "Alice" }
        ])
      judge = game.judge
      question = NormalizedString.new("New question?")

      game.start_new_round(question:, judge:)

      game.players.each do |player|
        assert_nil player.vote
        assert_not_predicate player, :voted?
      end
    end

    test "#start_new_round sets online players as playing" do
      game = build(:bu_completed_game, player_names: %w[Alice Bob Charlie],
        judge_name: "David")
      new_judge = game.players.find { |p| p.name.to_s == "Alice" }
      bob = game.players.find { |p| p.name.to_s == "Bob" }
      charlie = game.players.find { |p| p.name.to_s == "Charlie" }

      # Mark Bob as online (not old or new judge)
      PlayerConnections.instance.increment(bob.id)
      question = NormalizedString.new("What is your favorite animal?")

      game.start_new_round(question:, judge: new_judge)

      assert_predicate bob, :playing?
      assert_not_predicate charlie, :playing?
    end

    test "#start_new_round always sets judge as playing even if offline" do
      game = build(:bu_completed_game, player_names: %w[Alice Bob],
        judge_name: "Charlie")
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      question = NormalizedString.new("What is your favorite animal?")

      # Alice is offline but should be playing because she's the judge
      game.start_new_round(question:, judge: alice)

      assert_predicate alice, :playing?
      assert_not_predicate alice, :online?
    end

    test "#start_new_round returns the game" do
      game = build(:bu_completed_game, player_names: %w[Alice],
        judge_name: "Bob")
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      question = NormalizedString.new("What is your favorite animal?")

      assert_equal game, game.start_new_round(question:, judge: alice)
    end

    test "#start_new_round preserves player scores from previous round" do
      game = build(:bu_completed_game, player_names: %w[Alice Bob],
        judge_name: "Charlie")
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      bob = game.players.find { |p| p.name.to_s == "Bob" }
      charlie = game.players.find { |p| p.name.to_s == "Charlie" }

      # Set different scores
      alice.score = 5
      bob.score = 3
      charlie.score = 7

      question = NormalizedString.new("What is your favorite animal?")
      game.start_new_round(question:, judge: alice)

      assert_equal 5, alice.score
      assert_equal 3, bob.score
      assert_equal 7, charlie.score
    end

    test "#start_new_round persists changes after save" do
      game = create(:bu_completed_game, player_names: %w[Alice Bob],
        judge_name: "Charlie")
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      question = NormalizedString.new("What is your favorite animal?")

      game.start_new_round(question:, judge: alice)
      GameRepo.save(game)

      reloaded_game = GameRepo.find(game.id)
      assert_equal "What is your favorite animal?", reloaded_game.question.to_s
      assert_predicate reloaded_game.status, :polling?
      assert_equal alice.id, reloaded_game.judge.id
      reloaded_game.players.each do |player|
        assert_nil player.vote
      end
    end

    test "#start_new_round accepts minimum valid question length" do
      game = build(:bu_completed_game, judge_name: "Alice")
      judge = game.judge
      question = NormalizedString.new("Why")

      game.start_new_round(question:, judge:)

      assert_equal "Why", game.question.to_s
    end

    test "#start_new_round accepts maximum valid question length" do
      game = build(:bu_completed_game, judge_name: "Alice")
      judge = game.judge
      question = NormalizedString.new("a" * 160)

      game.start_new_round(question:, judge:)

      assert_equal 160, game.question.to_s.length
    end

    test "#start_new_round raises error with question too short" do
      game = build(:bu_completed_game, judge_name: "Alice")
      judge = game.judge
      short_question = NormalizedString.new("AB")

      error = assert_raises(ArgumentError) do
        game.start_new_round(question: short_question, judge:)
      end

      assert_match(/Question length must be between 3 and 160 characters/,
        error.message)
    end

    test "#start_new_round raises error with question too long" do
      game = build(:bu_completed_game, judge_name: "Alice")
      judge = game.judge
      long_question = NormalizedString.new("a" * 161)

      error = assert_raises(ArgumentError) do
        game.start_new_round(question: long_question, judge:)
      end

      assert_match(/Question length must be between 3 and 160 characters/,
        error.message)
    end

    test "#start_new_round raises error when game is not in completed status" do
      game = build(:bu_polling_game, judge_name: "Alice",
        player_names: %w[Bob])
      judge = game.judge
      question = NormalizedString.new("What is your favorite animal?")

      assert_predicate game.status, :polling?

      error = assert_raises(RuntimeError) do
        game.start_new_round(question:, judge:)
      end

      assert_equal "Game must be in completed status", error.message
    end

    test "#to_global_id builds a GlobalID for the game" do
      game = build(:bu_game)

      gid = game.to_global_id

      assert_equal "Game", gid.model_name
      assert_equal game.id, gid.model_id
    end
  end
end
