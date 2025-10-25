# frozen_string_literal: true

require "test_helper"

module BurnUnit
  class NewRoundFormTest < ActiveSupport::TestCase
    test "#valid? returns true with completed game and valid question" do
      game = build(:bu_completed_game, judge_name: "Alice")
      form = NewRoundForm.new(game:, question: "What is your favorite color?")

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true with question at minimum length" do
      game = build(:bu_completed_game, judge_name: "Alice")
      form = NewRoundForm.new(game:, question: "Why")

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true with question at maximum length" do
      game = build(:bu_completed_game, judge_name: "Alice")
      form = NewRoundForm.new(game:, question: "a" * 160)

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns false when game is not completed" do
      game = build(:bu_polling_game, judge_name: "Alice")
      form = NewRoundForm.new(game:, question: "What is your favorite color?")

      assert_predicate game.status, :polling?
      assert_not_predicate form, :valid?
      assert form.errors.added?(:base, message: "Game is not completed")
    end

    test "#valid? returns false with question too short" do
      game = build(:bu_completed_game, judge_name: "Alice")
      form = NewRoundForm.new(game:, question: "ab")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:question, message:
        "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with blank question" do
      game = build(:bu_completed_game, judge_name: "Alice")
      form = NewRoundForm.new(game:, question: "")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:question, message:
        "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with nil question" do
      game = build(:bu_completed_game, judge_name: "Alice")
      form = NewRoundForm.new(game:, question: nil)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:question, message:
        "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with question too long" do
      game = build(:bu_completed_game, judge_name: "Alice")
      form = NewRoundForm.new(game:, question: "a" * 161)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:question, message:
        "is too long (maximum is 160 characters)")
    end

    test "#valid? returns false with both game status and question invalid" do
      game = build(:bu_polling_game, judge_name: "Alice")
      form = NewRoundForm.new(game:, question: "ab")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:base, message: "Game is not completed")
      assert form.errors.added?(:question, message:
        "is too short (minimum is 3 characters)")
    end

    test "#valid? normalizes question with NormalizedString" do
      game = build(:bu_completed_game, judge_name: "Alice")
      form = NewRoundForm.new(game:,
        question: "  What  is  your  name?  ")

      assert_predicate form, :valid?
      assert_equal "What is your name?", form.question.to_s
    end

    test "#question returns NormalizedString instance" do
      game = build(:bu_completed_game, judge_name: "Alice")
      form = NewRoundForm.new(game:, question: "Why?")

      assert_instance_of NormalizedString, form.question
    end

    test "#errors returns Errors instance" do
      game = build(:bu_completed_game, judge_name: "Alice")
      form = NewRoundForm.new(game:, question: "Why?")

      assert_instance_of Errors, form.errors
    end
  end
end
