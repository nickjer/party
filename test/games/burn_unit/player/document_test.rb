# frozen_string_literal: true

require "test_helper"

module BurnUnit
  class Player
    class DocumentTest < ActiveSupport::TestCase
      test ".new raises when score is negative" do
        error = assert_raises(ArgumentError) do
          Document.new(judge: false, score: -1, vote: nil, playing: false)
        end

        assert_equal "Score cannot be negative", error.message
      end

      test ".parse round-trips through as_json" do
        original = Document.new(
          judge: true, score: 2, vote: "some_player_id", playing: true
        )

        parsed = Document.parse(
          JSON.parse(original.to_json, symbolize_names: true)
        )

        assert_equal original.judge, parsed.judge
        assert_equal original.score, parsed.score
        assert_equal original.vote, parsed.vote
        assert_equal original.playing, parsed.playing
      end

      test "#with validates score on mutation" do
        document = Document.new(
          judge: false, score: 0, vote: nil, playing: false
        )

        assert_raises(ArgumentError) { document.with(score: -5) }
      end

      test "#with returns a new document with the updated field" do
        document = Document.new(
          judge: false, score: 0, vote: nil, playing: false
        )

        updated = document.with(playing: true)

        assert_not document.playing
        assert updated.playing
        assert_equal document.judge, updated.judge
      end
    end
  end
end
