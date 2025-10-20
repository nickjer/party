# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class NewRoundFormTest < ActiveSupport::TestCase
    test "#valid? returns true when game is completed and question is valid" do
      game = create(:lq_completed_game)

      form = NewRoundForm.new(game:, question: "What is your favorite food?")

      assert_predicate game.status, :completed?
      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true with question at minimum length" do
      game = create(:lq_completed_game)

      form = NewRoundForm.new(game:, question: "Why")

      assert_predicate game.status, :completed?
      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true with question at maximum length" do
      game = create(:lq_completed_game)

      form = NewRoundForm.new(game:, question: "a" * 160)

      assert_predicate game.status, :completed?
      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns false when game is in polling phase" do
      game = create(:lq_game)

      form = NewRoundForm.new(game:, question: "Why?")

      assert_predicate game.status, :polling?
      assert_not_predicate form, :valid?
      assert form.errors.added?(:game, message: "Game is not completed")
    end

    test "#valid? returns false when game is in guessing phase" do
      game = create(:lq_matching_game)

      form = NewRoundForm.new(game:, question: "Why?")

      assert_predicate game.status, :guessing?
      assert_not_predicate form, :valid?
      assert form.errors.added?(:game, message: "Game is not completed")
    end

    test "#valid? returns false with question too short" do
      game = create(:lq_completed_game)

      form = NewRoundForm.new(game:, question: "ab")

      assert_predicate game.status, :completed?
      assert_not_predicate form, :valid?
      assert form.errors.added?(:question,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with blank question" do
      game = create(:lq_completed_game)

      form = NewRoundForm.new(game:, question: "")

      assert_predicate game.status, :completed?
      assert_not_predicate form, :valid?
      assert form.errors.added?(:question,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? returns true with nil question using random question" do
      game = create(:lq_completed_game)

      form = NewRoundForm.new(game:, question: nil)

      assert_predicate game.status, :completed?
      assert_predicate form, :valid?
      assert_not_predicate form.question.to_s, :empty?
    end

    test "#valid? returns false with question too long" do
      game = create(:lq_completed_game)

      form = NewRoundForm.new(game:, question: "a" * 161)

      assert_predicate game.status, :completed?
      assert_not_predicate form, :valid?
      assert form.errors.added?(:question,
        message: "is too long (maximum is 160 characters)")
    end

    test "#valid? returns false when game is polling and question is invalid" do
      game = create(:lq_game)

      form = NewRoundForm.new(game:, question: "ab")

      assert_predicate game.status, :polling?
      assert_not_predicate form, :valid?
      assert form.errors.added?(:game, message: "Game is not completed")
      assert form.errors.added?(:question,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? normalizes question with NormalizedString" do
      game = create(:lq_completed_game)

      form = NewRoundForm.new(game:, question: "  What  is  your  name?  ")

      assert_predicate form, :valid?
      assert_equal "What is your name?", form.question.to_s
    end

    test "#question returns NormalizedString instance" do
      game = create(:lq_completed_game)
      form = NewRoundForm.new(game:, question: "Why?")

      assert_instance_of NormalizedString, form.question
    end

    test "#errors returns Errors instance" do
      game = create(:lq_completed_game)
      form = NewRoundForm.new(game:, question: "Why?")

      assert_instance_of Errors, form.errors
    end
  end
end
