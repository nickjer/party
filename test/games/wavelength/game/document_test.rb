# frozen_string_literal: true

require "test_helper"

module Wavelength
  class Game
    class DocumentTest < ActiveSupport::TestCase
      def spectrum
        Spectrum.new(left: "Cold", right: "Hot")
      end

      def document
        Document.new(status: Status.setup, starting_team: Team.red,
          current_team: Team.red, psychic_id: nil, spectrum:,
          target: Target.new(position: 42), guess: nil, opponent_guess: nil,
          red_score: 0, blue_score: 0, winner: nil)
      end

      test ".parse round-trips through to_h" do
        original = document.with(status: Status.completed, psychic_id: "p1",
          guess: 30, opponent_guess: "left", red_score: 10, blue_score: 4,
          winner: Team.red)

        parsed = Document.parse(original.to_h)

        assert_predicate parsed.status, :completed?
        assert_equal "p1", parsed.psychic_id
        assert_equal spectrum, parsed.spectrum
        assert_equal 42, parsed.target.position
        assert_equal 30, parsed.guess
        assert_equal "left", parsed.opponent_guess
        assert_equal 10, parsed.red_score
        assert_equal 4, parsed.blue_score
        assert_equal Team.red, parsed.winner
      end

      test ".parse handles nil psychic_id, guess, and winner" do
        parsed = Document.parse(document.to_h)

        assert_nil parsed.psychic_id
        assert_nil parsed.guess
        assert_nil parsed.opponent_guess
        assert_nil parsed.winner
      end

      test "#with swaps in new values and keeps the rest" do
        updated = document.with(status: Status.guessing, guess: 70)

        assert_predicate updated.status, :guessing?
        assert_equal 70, updated.guess
        assert_equal Team.red, updated.starting_team
      end

      test "#to_h serializes scalars and value objects" do
        hash = document.to_h

        assert_equal "setup", hash[:status]
        assert_equal "red", hash[:starting_team]
        assert_equal({ left: "Cold", right: "Hot" }, hash[:spectrum])
        assert_equal 42, hash[:target]
        assert_nil hash[:winner]
      end
    end
  end
end
