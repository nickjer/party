# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class PlayerTest < ActiveSupport::TestCase
    test ".build raises error when name is too short" do
      game = build(:lq_game)
      user = build(:user)
      short_name = NormalizedString.new("AB")

      error = assert_raises(ArgumentError) do
        Player.build(game_id: game.id, user_id: user.id, name: short_name)
      end

      assert_match(/Name length must be between 3 and 25 characters/,
        error.message)
    end

    test "#answer= persists to database after save" do
      game = create(:lq_game)
      player = create(:lq_player, game:)
      new_answer = NormalizedString.new("Blue")

      player.answer = new_answer
      player.save!

      reloaded_game = reload(game:)
      reloaded_player = reloaded_game.find_player(player.id)

      assert_equal "Blue", reloaded_player.answer.to_s
    end

    test "#answer= raises error when answer is too long" do
      game = build(:lq_game)
      player = build(:lq_player, game:)
      long_answer = NormalizedString.new("a" * 81)

      error = assert_raises(ArgumentError) do
        player.answer = long_answer
      end

      assert_match(/Answer length must be between 3 and 80 characters/,
        error.message)
    end

    test "#answer= raises error when answer is too short" do
      game = build(:lq_game)
      player = build(:lq_player, game:)
      short_answer = NormalizedString.new("AB")

      error = assert_raises(ArgumentError) do
        player.answer = short_answer
      end

      assert_match(/Answer length must be between 3 and 80 characters/,
        error.message)
    end

    test "#guesser= persists to database after save" do
      game = create(:lq_game)
      player = create(:lq_player, game:)

      assert_not_predicate player, :guesser?

      player.guesser = true
      player.save!

      reloaded_game = reload(game:)
      reloaded_player = reloaded_game.find_player(player.id)

      assert_predicate reloaded_player, :guesser?
    end

    test "#name= persists to database after save" do
      game = create(:lq_game)
      player = create(:lq_player, game:)
      new_name = NormalizedString.new("NewName")

      player.name = new_name
      player.save!

      reloaded_game = reload(game:)
      reloaded_player = reloaded_game.find_player(player.id)

      assert_equal "NewName", reloaded_player.name.to_s
    end

    test "#name= raises error when name is too long" do
      game = build(:lq_game)
      player = build(:lq_player, game:)
      long_name = NormalizedString.new("a" * 26)

      error = assert_raises(ArgumentError) do
        player.name = long_name
      end

      assert_match(/Name length must be between 3 and 25 characters/,
        error.message)
    end

    test "#name= raises error when name is too short" do
      game = build(:lq_game)
      player = build(:lq_player, game:)
      short_name = NormalizedString.new("AB")

      error = assert_raises(ArgumentError) do
        player.name = short_name
      end

      assert_match(/Name length must be between 3 and 25 characters/,
        error.message)
    end

    test "#reset_answer persists to database after save" do
      game = create(:lq_game)
      player = create(:lq_player, game:, answer: "Blue")

      assert_predicate player, :answered?

      player.reset_answer
      player.save!

      reloaded_game = reload(game:)
      reloaded_player = reloaded_game.find_player(player.id)

      assert_not_predicate reloaded_player, :answered?
      assert_equal "", reloaded_player.answer.to_s
    end

    test "#score= persists to database after save" do
      game = create(:lq_game)
      player = create(:lq_player, game:)

      assert_equal 0, player.score

      player.score = 5
      player.save!

      reloaded_game = reload(game:)
      reloaded_player = reloaded_game.find_player(player.id)

      assert_equal 5, reloaded_player.score
    end

    test "#score= raises error when score is negative" do
      game = build(:lq_game)
      player = build(:lq_player, game:)

      error = assert_raises(ArgumentError) do
        player.score = -1
      end

      assert_equal "Score cannot be negative", error.message
    end
  end
end
