# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class GuessingRoundFormTest < ActiveSupport::TestCase
    test "#valid? returns true when game is polling and enough players " \
      "answered" do
      game = create(:lq_game, :with_players, :with_answers)

      form = GuessingRoundForm.new(game:)

      assert_predicate game.status, :polling?
      assert_operator game.players.count(&:answered?), :>=, GuessingRoundForm::MIN_ANSWERED
      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true with exactly minimum answered players" do
      game = create(:lq_game,
        players: [
          { name: "Bob", answer: "Blue" },
          { name: "Charlie", answer: "Red" }
        ])

      form = GuessingRoundForm.new(game:)

      assert_predicate game.status, :polling?
      assert_equal GuessingRoundForm::MIN_ANSWERED,
        game.players.count(&:answered?)
      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns false when game is not polling" do
      game = create(:lq_matching_game)

      form = GuessingRoundForm.new(game:)

      assert_predicate game.status, :guessing?
      assert_not_predicate form, :valid?
      assert form.errors.added?(:base, message: "Game is not polling")
    end

    test "#valid? returns false when not enough players answered" do
      game = create(:lq_game,
        players: [
          { name: "Bob", answer: "Blue" },
          { name: "Charlie", answer: "" }
        ])

      form = GuessingRoundForm.new(game:)

      assert_predicate game.status, :polling?
      assert_operator game.players.count(&:answered?), :<, GuessingRoundForm::MIN_ANSWERED
      assert_not_predicate form, :valid?
      assert form.errors.added?(:base,
        message: "Not enough players have answered (need at least 2)")
    end

    test "#valid? returns false when no players answered" do
      game = create(:lq_game, player_names: %w[Bob Charlie])

      form = GuessingRoundForm.new(game:)

      assert_predicate game.status, :polling?
      assert_equal 0, game.players.count(&:answered?)
      assert_not_predicate form, :valid?
      assert form.errors.added?(:base,
        message: "Not enough players have answered (need at least 2)")
    end

    test "#valid? returns false when only guesser in game" do
      game = create(:lq_game)

      form = GuessingRoundForm.new(game:)

      assert_predicate game.status, :polling?
      assert_equal 0, game.players.count(&:answered?)
      assert_not_predicate form, :valid?
      assert form.errors.added?(:base,
        message: "Not enough players have answered (need at least 2)")
    end

    test "#errors returns Errors instance" do
      game = create(:lq_game)
      form = GuessingRoundForm.new(game:)

      assert_instance_of Errors, form.errors
    end
  end
end
