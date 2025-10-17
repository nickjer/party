# frozen_string_literal: true

require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  test "#parsed_document returns JSON with symbolized keys" do
    player = create(:player,
      document: { answer: "Blue", guesser: false }.to_json)

    parsed = player.parsed_document

    assert_equal "Blue", parsed[:answer]
    assert_equal false, parsed[:guesser]
  end

  test "#parsed_document memoizes result" do
    player = create(:player, document: { test: "value" }.to_json)

    parsed1 = player.parsed_document
    parsed2 = player.parsed_document

    assert_same parsed1, parsed2
  end

  test "#document= clears memoized parsed_document" do
    player = create(:player, document: { old: "value" }.to_json)

    old_parsed = player.parsed_document
    player.document = { new: "value" }.to_json
    new_parsed = player.parsed_document

    assert_not_same old_parsed, new_parsed
    assert_equal "value", new_parsed[:new]
    assert_nil new_parsed[:old]
  end

  test "#name returns NormalizedString" do
    player = create(:player, name: "Alice")

    assert_instance_of NormalizedString, player.name
    assert_equal "Alice", player.name.to_s
  end

  test "#game returns associated game" do
    game = create(:game)
    player = create(:player, game:)

    assert_equal game, player.game
  end

  test "#user returns associated user" do
    user = create(:user)
    player = create(:player, user:)

    assert_equal user, player.user
  end

  test "#valid? returns false when name is not unique within game" do
    game = create(:game)
    create(:player, game:, name: "Alice")
    player = build(:player, game:, name: "alice")

    assert_not player.valid?
    assert player.errors.added?(:name, :taken, value: "alice")
  end

  test "#valid? returns false when normalized name matches existing player" do
    game = create(:game)
    create(:player, game:, name: "Alice")
    player = build(:player, game:, name: "Alice😀")

    assert_not player.valid?
    assert player.errors.added?(:name, :taken, value: "Alice😀")
  end

  test "#valid? returns false when user already has a player in game" do
    game = create(:game)
    existing_player = create(:player, game:, name: "Alice")
    player = build(:player, game:, user: existing_player.user, name: "Bob")

    assert_not player.valid?
    assert player.errors.added?(:user_id, :taken,
      value: existing_player.user.id)
  end
end
