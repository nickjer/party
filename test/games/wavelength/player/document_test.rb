# frozen_string_literal: true

require "test_helper"

module Wavelength
  class Player
    class DocumentTest < ActiveSupport::TestCase
      test ".parse round-trips through to_h" do
        parsed = Document.parse(Document.new(team: Team.blue,
          psychic_count: 2).to_h)

        assert_equal Team.blue, parsed.team
        assert_equal 2, parsed.psychic_count
      end

      test ".parse handles a nil team" do
        parsed = Document.parse({ team: nil, psychic_count: 0 })

        assert_nil parsed.team
      end

      test "#to_h serializes team and psychic_count" do
        document = Document.new(team: Team.red, psychic_count: 3)

        assert_equal({ team: "red", psychic_count: 3 }, document.to_h)
      end

      test "#to_h serializes a teamless player" do
        document = Document.new(team: nil, psychic_count: 0)

        assert_equal({ team: nil, psychic_count: 0 }, document.to_h)
      end

      test "#with swaps in new values and keeps the rest" do
        updated = Document.new(team: nil, psychic_count: 1).with(team: Team.red)

        assert_equal Team.red, updated.team
        assert_equal 1, updated.psychic_count
      end
    end
  end
end
