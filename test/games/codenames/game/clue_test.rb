# frozen_string_literal: true

require "test_helper"

module Codenames
  class Game
    class ClueTest < ActiveSupport::TestCase
      test ".parse round-trips through to_h" do
        original = clue(number: 2)

        parsed = Clue.parse(original.to_h)

        assert_equal original, parsed
        assert_equal "Ocean", parsed.word.to_s
        assert_equal 2, parsed.number
      end

      test ".parse round-trips an unlimited clue" do
        original = clue(number: nil)

        parsed = Clue.parse(original.to_h)

        assert_equal original, parsed
        assert_predicate parsed, :unlimited?
      end

      test "#initialize raises for a number outside 0-9" do
        assert_raises(ArgumentError) { clue(number: 10) }
        assert_raises(ArgumentError) { clue(number: -1) }
      end

      test "#guess_limit is the number plus one bonus guess" do
        assert_equal 2, clue(number: 1).guess_limit
        assert_equal 10, clue(number: 9).guess_limit
      end

      test "#guess_limit is nil for zero and unlimited clues" do
        assert_nil clue(number: 0).guess_limit
        assert_nil clue(number: nil).guess_limit
      end

      test "#unlimited? is true only without a number" do
        assert_predicate clue(number: nil), :unlimited?
        assert_not_predicate clue(number: 0), :unlimited?
      end

      test "#number_display shows the number or the infinity sign" do
        assert_equal "3", clue(number: 3).number_display
        assert_equal "∞", clue(number: nil).number_display
      end

      private

      def clue(number:)
        Clue.new(word: NormalizedString.new("Ocean"), number:)
      end
    end
  end
end
