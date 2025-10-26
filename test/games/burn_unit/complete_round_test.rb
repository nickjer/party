# frozen_string_literal: true

require "test_helper"

module BurnUnit
  class CompleteRoundTest < ActiveSupport::TestCase
    test "#call changes game status from polling to completed" do
      game = build(:bu_polling_game, judge_name: "Alice",
        player_names: %w[Bob])

      assert_predicate game.status, :polling?

      CompleteRound.new(game:).call

      assert_predicate game.status, :completed?
    end

    test "#call awards point to single winner" do
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

      CompleteRound.new(game:).call

      # Bob has 2 votes (from Alice and Charlie), everyone else has fewer
      assert_equal 1, bob.score
      assert_equal 0, alice.score
      assert_equal 0, charlie.score
      assert_equal 0, judge.score
    end

    test "#call awards points to multiple winners when tied" do
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

      CompleteRound.new(game:).call

      # Alice, Bob, and Judge all have 1 vote - all tied for winner
      assert_equal 1, alice.score
      assert_equal 1, bob.score
      assert_equal 0, charlie.score
      assert_equal 1, judge.score
    end

    test "#call awards no points when no one has votes" do
      game = build(:bu_polling_game, judge_name: "Judge",
        player_names: %w[Alice Bob Charlie])

      CompleteRound.new(game:).call

      game.players.each do |player|
        assert_equal 0, player.score
      end
    end

    test "#call preserves existing scores" do
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

      CompleteRound.new(game:).call

      # Alice and Bob tied with 1 vote each, so both get +1
      assert_equal 6, alice.score
      assert_equal 4, bob.score
      assert_equal 2, judge.score
    end

    test "#call returns the game" do
      game = build(:bu_polling_game, judge_name: "Alice",
        player_names: %w[Bob])

      result = CompleteRound.new(game:).call

      assert_equal game, result
    end

    test "#call persists changes after save" do
      game = create(:bu_polling_game,
        judge_name: "Judge",
        players: [
          { name: "Alice", vote_for: "Bob" },
          { name: "Bob", vote_for: "Alice" }
        ])
      bob_id = game.players.find { |p| p.name.to_s == "Bob" }.id
      alice_id = game.players.find { |p| p.name.to_s == "Alice" }.id

      CompleteRound.new(game:).call
      game.save!

      reloaded_game = Game.find(game.id)
      assert_predicate reloaded_game.status, :completed?

      bob = reloaded_game.players.find { |p| p.id == bob_id }
      alice = reloaded_game.players.find { |p| p.id == alice_id }
      assert_equal 1, bob.score
      assert_equal 1, alice.score
    end

    test "#call raises error when game is not in polling status" do
      game = build(:bu_completed_game, judge_name: "Alice",
        player_names: %w[Bob])

      assert_predicate game.status, :completed?

      error = assert_raises(RuntimeError) do
        CompleteRound.new(game:).call
      end

      assert_equal "Game must be in polling status", error.message
    end

    test "#call only awards points to playing players" do
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

      CompleteRound.new(game:).call

      # Judge has 2 votes and is the only winner
      # Alice is not playing so doesn't count as a candidate
      assert_equal 0, alice.score
      assert_equal 0, bob.score
      assert_equal 0, charlie.score
      assert_equal 1, judge.score
    end
  end
end
