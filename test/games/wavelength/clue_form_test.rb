# frozen_string_literal: true

require "test_helper"

module Wavelength
  class ClueFormTest < ActiveSupport::TestCase
    test "#valid? is true for a clue within the length bounds" do
      form = ClueForm.new(text: "Banana")

      assert_predicate form, :valid?
      assert_equal "Banana", form.text.to_s
    end

    test "#valid? normalizes surrounding and repeated whitespace" do
      form = ClueForm.new(text: "  Banana   split  ")

      assert form.valid?
      assert_equal "Banana split", form.text.to_s
    end

    test "#valid? is false for a blank clue" do
      form = ClueForm.new(text: "   ")

      assert_not form.valid?
      assert form.errors.added?(:text,
        message: "is too short (minimum is 1 characters)")
    end

    test "#valid? is false for a clue that is too long" do
      form = ClueForm.new(text: "x" * 51)

      assert_not form.valid?
      assert form.errors.added?(:text,
        message: "is too long (maximum is 50 characters)")
    end

    test "#valid? defaults to a blank clue" do
      assert_not_predicate ClueForm.new, :valid?
    end
  end
end
