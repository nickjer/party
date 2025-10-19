# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class NewGameFormTest < ActiveSupport::TestCase
    test "#valid? returns true with valid player name and question" do
      form = NewGameForm.new(player_name: "Alice",
        question: "What is your favorite color?")

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true with player name at minimum length" do
      form = NewGameForm.new(player_name: "Bob", question: "Why?")

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true with player name at maximum length" do
      form = NewGameForm.new(player_name: "a" * 25, question: "Why?")

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true with question at minimum length" do
      form = NewGameForm.new(player_name: "Bob", question: "Why")

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true with question at maximum length" do
      form = NewGameForm.new(player_name: "Bob", question: "a" * 160)

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns false with player name too short" do
      form = NewGameForm.new(player_name: "ab", question: "Why?")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:player_name,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with blank player name" do
      form = NewGameForm.new(player_name: "", question: "Why?")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:player_name,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with nil player name" do
      form = NewGameForm.new(player_name: nil, question: "Why?")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:player_name,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with player name too long" do
      form = NewGameForm.new(player_name: "a" * 26, question: "Why?")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:player_name,
        message: "is too long (maximum is 25 characters)")
    end

    test "#valid? returns false with question too short" do
      form = NewGameForm.new(player_name: "Bob", question: "ab")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:question,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with blank question" do
      form = NewGameForm.new(player_name: "Bob", question: "")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:question,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with nil question" do
      form = NewGameForm.new(player_name: "Bob", question: nil)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:question,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with question too long" do
      form = NewGameForm.new(player_name: "Bob", question: "a" * 161)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:question,
        message: "is too long (maximum is 160 characters)")
    end

    test "#valid? returns false with both player name and question invalid" do
      form = NewGameForm.new(player_name: "ab", question: "ab")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:player_name,
        message: "is too short (minimum is 3 characters)")
      assert form.errors.added?(:question,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? normalizes player name with NormalizedString" do
      form = NewGameForm.new(player_name: "  Alice  ", question: "Why?")

      assert_predicate form, :valid?
      assert_equal "Alice", form.player_name.to_s
    end

    test "#valid? normalizes question with NormalizedString" do
      form = NewGameForm.new(player_name: "Bob",
        question: "  What  is  your  name?  ")

      assert_predicate form, :valid?
      assert_equal "What is your name?", form.question.to_s
    end

    test "#player_name returns NormalizedString instance" do
      form = NewGameForm.new(player_name: "Alice", question: "Why?")

      assert_instance_of NormalizedString, form.player_name
    end

    test "#question returns NormalizedString instance" do
      form = NewGameForm.new(player_name: "Alice", question: "Why?")

      assert_instance_of NormalizedString, form.question
    end

    test "#errors returns Errors instance" do
      form = NewGameForm.new(player_name: "Alice", question: "Why?")

      assert_instance_of Errors, form.errors
    end
  end
end
