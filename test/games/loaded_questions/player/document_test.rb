# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class Player
    class DocumentTest < ActiveSupport::TestCase
      test ".new raises when score is negative" do
        error = assert_raises(ArgumentError) do
          Document.new(answer: Answer.empty, guesser: false, score: -1)
        end

        assert_equal "Score cannot be negative", error.message
      end

      test ".new allows an empty answer (sentinel for unanswered)" do
        document = Document.new(
          answer: Answer.empty,
          guesser: false,
          score: 0
        )

        assert_predicate document.answer, :blank?
      end

      test ".parse round-trips through as_json" do
        original = Document.new(
          answer: Answer.build(value: "Blue"),
          guesser: true,
          score: 3
        )

        parsed = Document.parse(
          JSON.parse(original.to_json, symbolize_names: true)
        )

        assert_equal original.answer, parsed.answer
        assert_equal original.guesser, parsed.guesser
        assert_equal original.score, parsed.score
      end

      test "#with validates score on mutation" do
        document = Document.new(
          answer: Answer.empty, guesser: false, score: 0
        )

        assert_raises(ArgumentError) { document.with(score: -5) }
      end

      test "#with returns a new document with the updated field" do
        document = Document.new(
          answer: Answer.empty, guesser: false, score: 0
        )

        updated = document.with(guesser: true)

        assert_not document.guesser
        assert updated.guesser
        assert_equal document.score, updated.score
      end
    end
  end
end
