# frozen_string_literal: true

require "test_helper"

module BurnUnit
  class VoteFormTest < ActiveSupport::TestCase
    test "#valid? returns true with valid candidate_id" do
      game = build(:bu_polling_game, judge_name: "Judge",
        player_names: %w[Alice Bob])
      current_player = game.players.find { |p| p.name.to_s == "Alice" }
      bob = game.players.find { |p| p.name.to_s == "Bob" }
      form = VoteForm.new(game:, current_player:, candidate_id: bob.id)

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns false when candidate_id is blank" do
      game = build(:bu_polling_game, judge_name: "Judge",
        player_names: %w[Alice])
      current_player = game.players.first
      form = VoteForm.new(game:, current_player:, candidate_id: "")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:candidate_id, message: "must be selected")
    end

    test "#valid? returns false when candidate_id is nil" do
      game = build(:bu_polling_game, judge_name: "Judge",
        player_names: %w[Alice])
      current_player = game.players.first
      form = VoteForm.new(game:, current_player:, candidate_id: nil)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:candidate_id, message: "must be selected")
    end

    test "#valid? returns false when candidate_id is not a valid candidate" do
      game = build(:bu_polling_game, judge_name: "Judge",
        player_names: %w[Alice])
      current_player = game.players.first
      invalid_id = "invalid_id"
      form = VoteForm.new(game:, current_player:, candidate_id: invalid_id)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:candidate_id,
        message: "is not a valid candidate")
    end

    test "#valid? returns false when voting for yourself" do
      game = build(:bu_polling_game, judge_name: "Judge",
        player_names: %w[Alice])
      current_player = game.players.first
      form = VoteForm.new(game:, current_player:,
        candidate_id: current_player.id)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:candidate_id,
        message: "cannot vote for yourself")
    end

    test "#valid? allows voting for judge" do
      game = build(:bu_polling_game, judge_name: "Judge",
        player_names: %w[Alice])
      current_player = game.players.find { |p| p.name.to_s == "Alice" }
      judge = game.judge
      form = VoteForm.new(game:, current_player:, candidate_id: judge.id)

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns false when candidate is not playing" do
      game = build(:bu_polling_game,
        judge_name: "Judge",
        players: [
          { name: "Alice" },
          { name: "Bob", not_playing: true }
        ])
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      bob = game.players.find { |p| p.name.to_s == "Bob" }

      assert_not_predicate bob, :playing?

      # Bob shouldn't be in candidates list
      candidate_ids = game.candidates.map(&:id)
      assert_not_includes candidate_ids, bob.id

      form = VoteForm.new(game:, current_player: alice, candidate_id: bob.id)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:candidate_id,
        message: "is not a valid candidate")
    end

    test "#show? returns true when candidate_id is blank" do
      game = build(:bu_polling_game, judge_name: "Judge",
        player_names: %w[Alice])
      current_player = game.players.first
      form = VoteForm.new(game:, current_player:, candidate_id: nil)

      assert_predicate form, :show?
    end

    test "#show? returns true when form has errors" do
      game = build(:bu_polling_game, judge_name: "Judge",
        player_names: %w[Alice])
      current_player = game.players.first
      form = VoteForm.new(game:, current_player:,
        candidate_id: current_player.id)

      form.valid? # Trigger validation to add errors

      assert_predicate form, :show?
    end

    test "#show? returns false when candidate_id is present and no errors" do
      game = build(:bu_polling_game, judge_name: "Judge",
        player_names: %w[Alice Bob])
      current_player = game.players.find { |p| p.name.to_s == "Alice" }
      bob = game.players.find { |p| p.name.to_s == "Bob" }
      form = VoteForm.new(game:, current_player:, candidate_id: bob.id)

      form.valid? # Trigger validation

      assert_not_predicate form, :show?
    end

    test "#errors returns Errors instance" do
      game = build(:bu_polling_game, judge_name: "Judge",
        player_names: %w[Alice])
      current_player = game.players.first
      form = VoteForm.new(game:, current_player:, candidate_id: nil)

      assert_instance_of Errors, form.errors
    end
  end
end
