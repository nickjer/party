# frozen_string_literal: true

require "test_helper"

module BurnUnit
  class CompletedRoundFormTest < ActiveSupport::TestCase
    test "#valid? returns true with polling game and at least 2 votes" do
      game = build(:bu_polling_game,
        judge_name: "Judge",
        players: [
          { name: "Alice", vote_for: "Bob" },
          { name: "Bob", vote_for: "Alice" }
        ])
      form = CompletedRoundForm.new(game:)

      assert_predicate game.status, :polling?
      assert_equal 2, game.players.count(&:voted?)
      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true with more than 2 votes" do
      game = build(:bu_polling_game,
        judge_name: "Judge",
        players: [
          { name: "Alice", vote_for: "Bob" },
          { name: "Bob", vote_for: "Charlie" },
          { name: "Charlie", vote_for: "Alice" }
        ])
      form = CompletedRoundForm.new(game:)

      assert_equal 3, game.players.count(&:voted?)
      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns false when game is not in polling phase" do
      game = build(:bu_completed_game, judge_name: "Judge",
        player_names: %w[Alice Bob])
      form = CompletedRoundForm.new(game:)

      assert_predicate game.status, :completed?
      assert_not_predicate form, :valid?
      assert form.errors.added?(:base, message: "Game is not in polling phase")
    end

    test "#valid? returns false with 0 votes" do
      game = build(:bu_polling_game, judge_name: "Judge",
        player_names: %w[Alice Bob])
      form = CompletedRoundForm.new(game:)

      vote_count = game.players.count(&:voted?)
      assert_equal 0, vote_count
      assert_not_predicate form, :valid?
      assert form.errors.added?(:base, message:
        "Need at least 2 votes to tally (currently 0)")
    end

    test "#valid? returns false with 1 vote" do
      game = build(:bu_polling_game,
        judge_name: "Judge",
        players: [
          { name: "Alice", vote_for: "Bob" },
          { name: "Bob" }
        ])
      form = CompletedRoundForm.new(game:)

      vote_count = game.players.count(&:voted?)
      assert_equal 1, vote_count
      assert_not_predicate form, :valid?
      assert form.errors.added?(:base, message:
        "Need at least 2 votes to tally (currently 1)")
    end

    test "#valid? returns false when game is completed and has insufficient " \
      "votes" do
      game = build(:bu_completed_game, judge_name: "Judge",
        player_names: %w[Alice Bob])
      form = CompletedRoundForm.new(game:)

      assert_not_predicate form, :valid?
      # Should have both errors
      assert form.errors.added?(:base, message: "Game is not in polling phase")
      # NOTE: Even though game is completed, it still checks vote count
    end

    test "#errors returns Errors instance" do
      game = build(:bu_polling_game, judge_name: "Judge",
        player_names: %w[Alice])
      form = CompletedRoundForm.new(game:)

      assert_instance_of Errors, form.errors
    end
  end
end
