# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class CompletedRoundFormTest < ActiveSupport::TestCase
    test "#errors returns Errors instance" do
      game = build(:lq_game)
      form = CompletedRoundForm.new(game:)

      assert_instance_of Errors, form.errors
    end

    test "#valid? returns false when game is in completed phase" do
      game = build(:lq_completed_game)

      form = CompletedRoundForm.new(game:)

      assert_predicate game.status, :completed?
      assert_not_predicate form, :valid?
      assert form.errors.added?(:base, message: "Game is not in guessing phase")
    end

    test "#valid? returns false when game is in polling phase" do
      game = build(:lq_game)

      form = CompletedRoundForm.new(game:)

      assert_predicate game.status, :polling?
      assert_not_predicate form, :valid?
      assert form.errors.added?(:base, message: "Game is not in guessing phase")
    end

    test "#valid? returns true when game is in guessing phase" do
      game = build(:lq_matching_game)

      form = CompletedRoundForm.new(game:)

      assert_predicate game.status, :guessing?
      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end
  end
end
