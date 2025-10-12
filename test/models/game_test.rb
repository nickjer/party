require "test_helper"

class GameTest < ActiveSupport::TestCase
  test "#kind returns symbol" do
    game = create(:game, kind: "loaded_questions")

    assert_equal :loaded_questions, game.kind
  end

  test "#parsed_document returns JSON with symbolized keys" do
    game = create(:game, document: { question: "Test?", status: "polling" }.to_json)

    parsed = game.parsed_document

    assert_equal "Test?", parsed[:question]
    assert_equal "polling", parsed[:status]
  end

  test "#parsed_document memoizes result" do
    game = create(:game, document: { test: "value" }.to_json)

    parsed1 = game.parsed_document
    parsed2 = game.parsed_document

    assert_same parsed1, parsed2
  end

  test "#document= clears memoized parsed_document" do
    game = create(:game, document: { old: "value" }.to_json)

    old_parsed = game.parsed_document
    game.document = { new: "value" }.to_json
    new_parsed = game.parsed_document

    assert_not_same old_parsed, new_parsed
    assert_equal "value", new_parsed[:new]
    assert_nil new_parsed[:old]
  end

  test "#players returns associated players" do
    game = create(:game)
    player1, player2 = create_pair(:player, game:)

    assert_equal 2, game.players.count
    assert_includes game.players, player1
    assert_includes game.players, player2
  end

  test "#valid? returns false when slug is not unique" do
    create(:game, slug: "abc123")
    game = build(:game, slug: "abc123")

    assert_not game.valid?
    assert game.errors.added?(:slug, :taken, value: "abc123")
  end
end
