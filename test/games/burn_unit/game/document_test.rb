# frozen_string_literal: true

require "test_helper"

module BurnUnit
  class Game
    class DocumentTest < ActiveSupport::TestCase
      test ".new raises when question is too short" do
        error = assert_raises(ArgumentError) do
          Document.new(
            question: NormalizedString.new("ab"), status: Status.polling
          )
        end

        assert_match(/Question length must be between 3 and 160 characters/,
          error.message)
      end

      test ".new raises when question is too long" do
        error = assert_raises(ArgumentError) do
          Document.new(
            question: NormalizedString.new("a" * 161),
            status: Status.polling
          )
        end

        assert_match(/Question length must be between 3 and 160 characters/,
          error.message)
      end

      test ".parse round-trips through as_json" do
        original = Document.new(
          question: NormalizedString.new("Why?"),
          status: Status.completed
        )

        parsed = Document.parse(
          JSON.parse(original.to_json, symbolize_names: true)
        )

        assert_equal original.question, parsed.question
        assert_equal original.status, parsed.status
      end

      test "#with validates question on mutation" do
        document = Document.new(
          question: NormalizedString.new("Valid"), status: Status.polling
        )

        assert_raises(ArgumentError) do
          document.with(question: NormalizedString.new("ab"))
        end
      end

      test "#with returns a new document with the updated field" do
        document = Document.new(
          question: NormalizedString.new("Original"),
          status: Status.polling
        )

        updated = document.with(status: Status.completed)

        assert_equal Status.polling, document.status
        assert_equal Status.completed, updated.status
        assert_equal document.question, updated.question
      end
    end
  end
end
