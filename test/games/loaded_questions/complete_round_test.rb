# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class CompleteRoundTest < ActiveSupport::TestCase
    test "#call transitions game from guessing to completed status" do
      game = create(:lq_matching_game, player_names: %w[Alice Bob])

      assert_predicate game.status, :guessing?

      CompleteRound.new(game:).call

      assert_predicate game.status, :completed?
    end

    test "#call updates guesser score with number of correct guesses" do
      game = create(:lq_matching_game, player_names: %w[Alice Bob])
      guesser = game.guesser

      assert_equal 0, guesser.score

      # Make all guesses correct
      non_guessers = game.players.reject(&:guesser?)
      correct_guesses =
        non_guessers.map do |player|
          Game::GuessedAnswer.new(player:, guessed_player: player)
        end

      game.guesses = Game::Guesses.new(guesses: correct_guesses)
      game.save!

      game = reload(game:)
      assert_equal 2, game.guesses.score

      CompleteRound.new(game:).call

      assert_equal 2, game.guesser.score
    end

    test "#call adds to existing guesser score" do
      game = create(:lq_matching_game, player_names: %w[Alice Bob Charlie])
      guesser = game.guesser
      guesser.score = 5
      guesser.save!

      # Make one guess correct, swap the other two
      player1, player2, player3 = game.players.reject(&:guesser?)

      guesses = [
        Game::GuessedAnswer.new(player: player1, guessed_player: player1),
        Game::GuessedAnswer.new(player: player2, guessed_player: player3),
        Game::GuessedAnswer.new(player: player3, guessed_player: player2)
      ]

      game.guesses = Game::Guesses.new(guesses:)
      game.save!

      game = reload(game:)
      assert_equal 1, game.guesses.score

      CompleteRound.new(game:).call

      guesser_after = game.guesser
      assert_equal 6, guesser_after.score
    end

    test "#call raises error when game is not in guessing status" do
      game = create(:lq_game, player_names: %w[Alice Bob])

      assert_predicate game.status, :polling?

      error = assert_raises(RuntimeError) do
        CompleteRound.new(game:).call
      end

      assert_equal "Game must be in guessing status", error.message
    end

    test "#call returns the game" do
      game = create(:lq_matching_game, player_names: %w[Alice Bob])

      result = CompleteRound.new(game:).call

      assert_equal game, result
    end
  end
end
