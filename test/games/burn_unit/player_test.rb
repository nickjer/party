# frozen_string_literal: true

require "test_helper"

module BurnUnit
  class PlayerTest < ActiveSupport::TestCase
    test ".build raises error when name is too long" do
      game = build(:bu_game)
      user = build(:user)
      long_name = NormalizedString.new("a" * 26)

      error = assert_raises(ArgumentError) do
        Player.build(game_id: game.id, user_id: user.id, name: long_name)
      end

      assert_match(/Name length must be between 3 and 25 characters/,
        error.message)
    end

    test ".build raises error when name is too short" do
      game = build(:bu_game)
      user = build(:user)
      short_name = NormalizedString.new("AB")

      error = assert_raises(ArgumentError) do
        Player.build(game_id: game.id, user_id: user.id, name: short_name)
      end

      assert_match(/Name length must be between 3 and 25 characters/,
        error.message)
    end

    test "#judge= persists to database after save" do
      game = create(:bu_game)
      player = create(:bu_player, game:)

      assert_not_predicate player, :judge?

      player.judge = true
      player.save!

      reloaded_game = reload(game:)
      reloaded_player = reloaded_game.players.find { |p| p.id == player.id }

      assert_predicate reloaded_player, :judge?
    end

    test "#name= persists to database after save" do
      game = create(:bu_game)
      player = create(:bu_player, game:)
      new_name = NormalizedString.new("NewName")

      player.name = new_name
      player.save!

      reloaded_game = reload(game:)
      reloaded_player = reloaded_game.players.find { |p| p.id == player.id }

      assert_equal "NewName", reloaded_player.name.to_s
    end

    test "#name= raises error when name is too long" do
      game = build(:bu_game)
      player = build(:bu_player, game:)
      long_name = NormalizedString.new("a" * 26)

      error = assert_raises(ArgumentError) do
        player.name = long_name
      end

      assert_match(/Name length must be between 3 and 25 characters/,
        error.message)
    end

    test "#name= raises error when name is too short" do
      game = build(:bu_game)
      player = build(:bu_player, game:)
      short_name = NormalizedString.new("AB")

      error = assert_raises(ArgumentError) do
        player.name = short_name
      end

      assert_match(/Name length must be between 3 and 25 characters/,
        error.message)
    end

    test "#playing= persists to database after save" do
      game = create(:bu_game)
      player = create(:bu_player, game:, playing: false)

      assert_not_predicate player, :playing?

      player.playing = true
      player.save!

      reloaded_game = reload(game:)
      reloaded_player = reloaded_game.players.find { |p| p.id == player.id }

      assert_predicate reloaded_player, :playing?
    end

    test "#score= persists to database after save" do
      game = create(:bu_game)
      player = create(:bu_player, game:)

      assert_equal 0, player.score

      player.score = 5
      player.save!

      reloaded_game = reload(game:)
      reloaded_player = reloaded_game.players.find { |p| p.id == player.id }

      assert_equal 5, reloaded_player.score
    end

    test "#score= raises error when score is negative" do
      game = build(:bu_game)
      player = build(:bu_player, game:)

      error = assert_raises(ArgumentError) do
        player.score = -1
      end

      assert_equal "Score cannot be negative", error.message
    end

    test "#vote= persists to database after save" do
      game = create(:bu_polling_game, player_names: %w[Alice Bob])
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      bob = game.players.find { |p| p.name.to_s == "Bob" }

      assert_nil alice.vote
      assert_not_predicate alice, :voted?

      alice.vote = bob.id
      alice.save!

      reloaded_game = reload(game:)
      reloaded_alice = reloaded_game.players.find { |p| p.id == alice.id }

      assert_equal bob.id, reloaded_alice.vote
      assert_predicate reloaded_alice, :voted?
    end

    test "#voted? returns false when vote is nil" do
      game = build(:bu_game)
      player = build(:bu_player, game:)

      assert_not_predicate player, :voted?
    end

    test "#voted? returns true when vote is present" do
      game = build(:bu_polling_game, player_names: %w[Alice Bob])
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      bob = game.players.find { |p| p.name.to_s == "Bob" }

      alice.vote = bob.id

      assert_predicate alice, :voted?
    end
  end
end
