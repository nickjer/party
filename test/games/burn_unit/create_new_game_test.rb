# frozen_string_literal: true

require "test_helper"

module BurnUnit
  class CreateNewGameTest < ActiveSupport::TestCase
    test "#call creates game with question and polling status" do
      user = build(:user)
      question = NormalizedString.new("What is your favorite color?")

      game = CreateNewGame.new(user_id: user.id,
        player_name: NormalizedString.new("Alice"), question:).call

      assert_equal "What is your favorite color?", game.question.to_s
      assert_predicate game.status, :polling?
    end

    test "#call creates judge player with correct attributes" do
      user = build(:user)
      question = NormalizedString.new("What is your favorite color?")

      game = CreateNewGame.new(user_id: user.id,
        player_name: NormalizedString.new("Alice"), question:).call

      assert_equal 1, game.players.size
      judge = game.judge
      assert_equal user.id, judge.user_id
      assert_equal "Alice", judge.name.to_s
      assert_predicate judge, :judge?
      assert_predicate judge, :playing?
      assert_equal 0, judge.score
      assert_nil judge.vote
      assert_not_predicate judge, :voted?
    end

    test "#call returns unsaved game and player" do
      user = build(:user)
      question = NormalizedString.new("What is your favorite color?")

      game = CreateNewGame.new(user_id: user.id,
        player_name: NormalizedString.new("Alice"), question:).call

      assert_predicate game.to_model, :new_record?
      assert_predicate game.judge.to_model, :new_record?
    end

    test "#call persists game and player data after save" do
      user = create(:user)
      question = NormalizedString.new("What is your favorite color?")

      game = CreateNewGame.new(user_id: user.id,
        player_name: NormalizedString.new("Alice"), question:).call
      game.save!

      assert_not_predicate game.to_model, :new_record?
      assert_not_predicate game.judge.to_model, :new_record?

      reloaded_game = Game.find(game.id)
      assert_equal "What is your favorite color?", reloaded_game.question.to_s
      assert_predicate reloaded_game.status, :polling?

      judge = reloaded_game.judge
      assert_equal user.id, judge.user_id
      assert_equal "Alice", judge.name.to_s
      assert_predicate judge, :judge?
      assert_predicate judge, :playing?
    end

    test "#call normalizes player name" do
      user = build(:user)
      question = NormalizedString.new("What is your favorite color?")
      name = NormalizedString.new("  Alice  ")

      game = CreateNewGame.new(user_id: user.id, player_name: name,
        question:).call

      assert_equal "Alice", game.judge.name.to_s
    end

    test "#call accepts minimum and maximum valid question lengths" do
      user = build(:user)

      min_game = CreateNewGame.new(user_id: user.id,
        player_name: NormalizedString.new("Alice"),
        question: NormalizedString.new("Why")).call
      assert_equal "Why", min_game.question.to_s

      max_game = CreateNewGame.new(user_id: user.id,
        player_name: NormalizedString.new("Bob"),
        question: NormalizedString.new("a" * 160)).call
      assert_equal 160, max_game.question.to_s.length
    end

    test "#call raises error with question too short" do
      user = build(:user)
      short_question = NormalizedString.new("AB")

      error = assert_raises(ArgumentError) do
        CreateNewGame.new(user_id: user.id,
          player_name: NormalizedString.new("Alice"),
          question: short_question).call
      end

      assert_match(/Question length must be between 3 and 160 characters/,
        error.message)
    end

    test "#call raises error with question too long" do
      user = build(:user)
      long_question = NormalizedString.new("a" * 161)

      error = assert_raises(ArgumentError) do
        CreateNewGame.new(user_id: user.id,
          player_name: NormalizedString.new("Alice"),
          question: long_question).call
      end

      assert_match(/Question length must be between 3 and 160 characters/,
        error.message)
    end

    test "#call raises error with player name too short" do
      user = build(:user)
      question = NormalizedString.new("What is your favorite color?")
      short_name = NormalizedString.new("AB")

      error = assert_raises(ArgumentError) do
        CreateNewGame.new(user_id: user.id, player_name: short_name,
          question:).call
      end

      assert_match(/Name length must be between 3 and 25 characters/,
        error.message)
    end

    test "#call raises error with player name too long" do
      user = build(:user)
      question = NormalizedString.new("What is your favorite color?")
      long_name = NormalizedString.new("a" * 26)

      error = assert_raises(ArgumentError) do
        CreateNewGame.new(user_id: user.id, player_name: long_name,
          question:).call
      end

      assert_match(/Name length must be between 3 and 25 characters/,
        error.message)
    end
  end
end
