# frozen_string_literal: true

require "test_helper"

module Codenames
  class Player
    class DocumentTest < ActiveSupport::TestCase
      test "#to_h serializes team and spymaster" do
        document = Document.new(team: Team.red, spymaster: true)

        assert_equal({ team: "red", spymaster: true }, document.to_h)
      end

      test "#to_h serializes a teamless player" do
        document = Document.new(team: nil, spymaster: false)

        assert_equal({ team: nil, spymaster: false }, document.to_h)
      end

      test ".parse round-trips through to_h" do
        parsed = Document.parse(Document.new(team: Team.blue,
          spymaster: false).to_h)

        assert_equal Team.blue, parsed.team
        assert_not parsed.spymaster
      end

      test ".parse handles a nil team" do
        parsed = Document.parse({ team: nil, spymaster: false })

        assert_nil parsed.team
      end

      test "#with swaps in new values" do
        updated = Document.new(team: nil, spymaster: false).with(team: Team.red)

        assert_equal Team.red, updated.team
      end
    end
  end
end
