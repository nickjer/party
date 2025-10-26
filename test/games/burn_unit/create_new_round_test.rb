# frozen_string_literal: true

require "test_helper"

module BurnUnit
  class CreateNewRoundTest < ActiveSupport::TestCase
    test "#call updates game with new question and polling status" do
      game = build(:bu_completed_game, player_names: %w[Alice Bob],
        judge_name: "Charlie")
      new_judge = game.players.find { |p| p.name.to_s == "Alice" }
      question = NormalizedString.new("What is your favorite animal?")

      CreateNewRound.new(game:, judge: new_judge, question:).call

      assert_equal "What is your favorite animal?", game.question.to_s
      assert_predicate game.status, :polling?
    end

    test "#call sets new judge correctly" do
      game = build(:bu_completed_game, player_names: %w[Alice Bob],
        judge_name: "Charlie")
      new_judge = game.players.find { |p| p.name.to_s == "Alice" }
      question = NormalizedString.new("What is your favorite animal?")

      CreateNewRound.new(game:, judge: new_judge, question:).call

      assert_equal new_judge, game.judge
      assert_predicate new_judge, :judge?
      game.players.reject { |p| p == new_judge }.each do |player|
        assert_not_predicate player, :judge?
      end
    end

    test "#call clears all player votes" do
      game = build(:bu_polling_game,
        judge_name: "Judge",
        players: [
          { name: "Alice", vote_for: "Bob" },
          { name: "Bob", vote_for: "Alice" }
        ])
      judge = game.judge
      question = NormalizedString.new("New question?")

      CreateNewRound.new(game:, judge:, question:).call

      game.players.each do |player|
        assert_nil player.vote
        assert_not_predicate player, :voted?
      end
    end

    test "#call sets online players as playing" do
      game = build(:bu_completed_game, player_names: %w[Alice Bob Charlie],
        judge_name: "David")
      new_judge = game.players.find { |p| p.name.to_s == "Alice" }
      bob = game.players.find { |p| p.name.to_s == "Bob" }
      charlie = game.players.find { |p| p.name.to_s == "Charlie" }

      # Mark Bob as online (not old or new judge)
      PlayerConnections.instance.increment(bob.id)
      question = NormalizedString.new("What is your favorite animal?")

      CreateNewRound.new(game:, judge: new_judge, question:).call

      assert_predicate bob, :playing?
      assert_not_predicate charlie, :playing?
    end

    test "#call always sets judge as playing even if offline" do
      game = build(:bu_completed_game, player_names: %w[Alice Bob],
        judge_name: "Charlie")
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      question = NormalizedString.new("What is your favorite animal?")

      # Alice is offline but should be playing because she's the judge
      CreateNewRound.new(game:, judge: alice, question:).call

      assert_predicate alice, :playing?
      assert_not_predicate alice, :online?
    end

    test "#call returns the game" do
      game = build(:bu_completed_game, player_names: %w[Alice],
        judge_name: "Bob")
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      question = NormalizedString.new("What is your favorite animal?")

      result = CreateNewRound.new(game:, judge: alice, question:).call

      assert_equal game, result
    end

    test "#call preserves player scores from previous round" do
      game = build(:bu_completed_game, player_names: %w[Alice Bob],
        judge_name: "Charlie")
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      bob = game.players.find { |p| p.name.to_s == "Bob" }
      charlie = game.players.find { |p| p.name.to_s == "Charlie" }

      # Set different scores
      alice.score = 5
      bob.score = 3
      charlie.score = 7

      question = NormalizedString.new("What is your favorite animal?")
      CreateNewRound.new(game:, judge: alice, question:).call

      assert_equal 5, alice.score
      assert_equal 3, bob.score
      assert_equal 7, charlie.score
    end

    test "#call persists changes after save" do
      game = create(:bu_completed_game, player_names: %w[Alice Bob],
        judge_name: "Charlie")
      alice = game.players.find { |p| p.name.to_s == "Alice" }
      question = NormalizedString.new("What is your favorite animal?")

      CreateNewRound.new(game:, judge: alice, question:).call
      game.save!

      reloaded_game = Game.find(game.id)
      assert_equal "What is your favorite animal?", reloaded_game.question.to_s
      assert_predicate reloaded_game.status, :polling?
      assert_equal alice.id, reloaded_game.judge.id
      reloaded_game.players.each do |player|
        assert_nil player.vote
      end
    end

    test "#call accepts minimum valid question length" do
      game = build(:bu_completed_game, judge_name: "Alice")
      judge = game.judge
      question = NormalizedString.new("Why")

      CreateNewRound.new(game:, judge:, question:).call

      assert_equal "Why", game.question.to_s
    end

    test "#call accepts maximum valid question length" do
      game = build(:bu_completed_game, judge_name: "Alice")
      judge = game.judge
      question = NormalizedString.new("a" * 160)

      CreateNewRound.new(game:, judge:, question:).call

      assert_equal 160, game.question.to_s.length
    end

    test "#call raises error with question too short" do
      game = build(:bu_completed_game, judge_name: "Alice")
      judge = game.judge
      short_question = NormalizedString.new("AB")

      error = assert_raises(ArgumentError) do
        CreateNewRound.new(game:, judge:, question: short_question).call
      end

      assert_match(/Question length must be between 3 and 160 characters/,
        error.message)
    end

    test "#call raises error with question too long" do
      game = build(:bu_completed_game, judge_name: "Alice")
      judge = game.judge
      long_question = NormalizedString.new("a" * 161)

      error = assert_raises(ArgumentError) do
        CreateNewRound.new(game:, judge:, question: long_question).call
      end

      assert_match(/Question length must be between 3 and 160 characters/,
        error.message)
    end
  end
end
