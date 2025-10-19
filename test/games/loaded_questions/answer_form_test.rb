# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class AnswerFormTest < ActiveSupport::TestCase
    test "#valid? returns true with valid answer" do
      form = AnswerForm.new(answer: "Valid answer")

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true with answer at minimum length" do
      form = AnswerForm.new(answer: "abc")

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns true with answer at maximum length" do
      form = AnswerForm.new(answer: "a" * 80)

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
    end

    test "#valid? returns false with answer too short" do
      form = AnswerForm.new(answer: "ab")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:answer,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with blank answer" do
      form = AnswerForm.new(answer: "")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:answer,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with nil answer" do
      form = AnswerForm.new(answer: nil)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:answer,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with answer too long" do
      form = AnswerForm.new(answer: "a" * 81)

      assert_not_predicate form, :valid?
      assert form.errors.added?(:answer,
        message: "is too long (maximum is 80 characters)")
    end

    test "#valid? normalizes answer with NormalizedString" do
      form = AnswerForm.new(answer: "  Test  Answer  ")

      assert_predicate form, :valid?
      assert_equal "Test Answer", form.answer.to_s
    end

    test "#show? returns true when answer is blank" do
      form = AnswerForm.new(answer: "")

      assert_predicate form.answer, :blank?
      assert_predicate form, :show?
    end

    test "#show? returns true when errors are present" do
      form = AnswerForm.new(answer: "ab")
      form.valid?

      assert_not_predicate form.errors, :empty?
      assert_predicate form, :show?
    end

    test "#show? returns false when answer is valid and no errors" do
      form = AnswerForm.new(answer: "Valid answer")
      form.valid?

      assert_predicate form, :valid?
      assert_predicate form.errors, :empty?
      assert_not_predicate form, :show?
    end

    test "#answer returns NormalizedString instance" do
      form = AnswerForm.new(answer: "Test")

      assert_instance_of NormalizedString, form.answer
    end

    test "#errors returns Errors instance" do
      form = AnswerForm.new(answer: "Test")

      assert_instance_of Errors, form.errors
    end
  end
end
