# frozen_string_literal: true

require "test_helper"

module Codenames
  class ClueFormTest < ActiveSupport::TestCase
    test "#valid? is true for a word and number within bounds" do
      form = ClueForm.new(word: "Ocean", number: "2")

      assert_predicate form, :valid?
      assert_equal "Ocean", form.word.to_s
      assert_equal 2, form.parsed_number
    end

    test "#valid? accepts an unlimited number" do
      form = ClueForm.new(word: "Ocean", number: "unlimited")

      assert_predicate form, :valid?
      assert_nil form.parsed_number
    end

    test "#valid? normalizes surrounding and repeated whitespace" do
      form = ClueForm.new(word: "  New   York  ", number: "1")

      assert_predicate form, :valid?
      assert_equal "New York", form.word.to_s
    end

    test "#valid? is false for a blank word" do
      form = ClueForm.new(word: "   ", number: "1")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:word,
        message: "is too short (minimum is 1 characters)")
    end

    test "#valid? is false for a word that is too long" do
      form = ClueForm.new(word: "x" * 51, number: "1")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:word,
        message: "is too long (maximum is 50 characters)")
    end

    test "#valid? is false for a missing number" do
      form = ClueForm.new(word: "Ocean")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:number, message: "must be 0-9 or unlimited")
    end

    test "#valid? is false for a number outside the allowed set" do
      form = ClueForm.new(word: "Ocean", number: "10")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:number, message: "must be 0-9 or unlimited")
    end

    test "#valid? defaults to a blank form" do
      assert_not_predicate ClueForm.new, :valid?
    end

    test "#selected_number keeps a number within the allowed set" do
      assert_equal "0", ClueForm.new(word: "Ocean", number: "0").selected_number
      assert_equal "unlimited",
        ClueForm.new(word: "Ocean", number: "unlimited").selected_number
    end

    test "#selected_number falls back to the default otherwise" do
      assert_equal "1", ClueForm.new.selected_number
      assert_equal "1",
        ClueForm.new(word: "Ocean", number: "10").selected_number
    end
  end
end
