# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class BeginGuessingRoundTest < ActiveSupport::TestCase
    test "#call transitions game from polling to guessing status" do
      game = create(:lq_game, players: [
        { name: "Alice", answer: "Blue" },
        { name: "Bob", answer: "Red" }
      ])

      assert_predicate game.status, :polling?

      BeginGuessingRound.new(game:).call

      assert_predicate game.status, :guessing?
    end

    test "#call creates shuffled guess pairs from answered players" do
      game = create(:lq_game, players: [
        { name: "Alice", answer: "Blue" },
        { name: "Bob", answer: "Red" },
        { name: "Charlie", answer: "" }
      ])

      BeginGuessingRound.new(game:).call

      assert_equal 2, game.guesses.size

      # Verify all players who answered have a guess
      answered_players = game.players.select(&:answered?)
      answered_players.each do |player|
        guess = game.guesses.find(player.id)

        assert_not_nil guess
        assert_equal player.id, guess.player.id
      end
    end

    test "#call raises error when game is not in polling status" do
      game = create(:lq_matching_game, player_names: %w[Alice Bob])

      assert_predicate game.status, :guessing?

      error = assert_raises(RuntimeError) do
        BeginGuessingRound.new(game:).call
      end

      assert_equal "Game must be in polling status", error.message
    end

    test "#call returns the game" do
      game = create(:lq_game, players: [
        { name: "Alice", answer: "Blue" },
        { name: "Bob", answer: "Red" }
      ])

      result = BeginGuessingRound.new(game:).call

      assert_equal game, result
    end
  end
end
