# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class Game
    class GuessesTest < ActiveSupport::TestCase
      test "#find raises ActiveRecord::RecordNotFound when player not found" do
        game = build(:lq_matching_game, player_names: %w[Alice Bob])

        error = assert_raises(RuntimeError) { game.guesses.find(999_999) }

        assert_equal "Couldn't find guessed answer", error.message
      end

      test "#find returns guessed answer for player" do
        game = build(:lq_matching_game, player_names: %w[Alice Bob])
        non_guesser = game.players.reject(&:guesser?).first

        result = game.guesses.find(non_guesser.id)

        assert_equal non_guesser.id, result.player.id
      end

      test "#initialize raises error when duplicate guessed player found" do
        game = build(:lq_matching_game, player_names: %w[Alice Bob])
        player1, player2 = game.players.reject(&:guesser?)

        guesses = [
          Game::GuessedAnswer.new(player: player1, guessed_player: player1),
          Game::GuessedAnswer.new(player: player2, guessed_player: player1)
        ]

        error = assert_raises(RuntimeError) do
          Game::Guesses.new(guesses:)
        end

        assert_equal "Duplicate guessed player found in guesses", error.message
      end

      test "#initialize raises error when duplicate player found" do
        game = build(:lq_matching_game, player_names: %w[Alice Bob])
        player1, player2 = game.players.reject(&:guesser?)

        guesses = [
          Game::GuessedAnswer.new(player: player1, guessed_player: player1),
          Game::GuessedAnswer.new(player: player1, guessed_player: player2)
        ]

        error = assert_raises(RuntimeError) do
          Game::Guesses.new(guesses:)
        end

        assert_equal "Duplicate player found in guesses", error.message
      end

      test "#swap raises error when first player not found" do
        game = build(:lq_matching_game, player_names: %w[Alice Bob])
        second_player = game.players.reject(&:guesser?).first

        error = assert_raises(RuntimeError) do
          game.guesses.swap(player_id1: 999_999, player_id2: second_player.id)
        end

        assert_equal "Player 999999 not found", error.message
      end

      test "#swap raises error when second player not found" do
        game = build(:lq_matching_game, player_names: %w[Alice Bob])
        first_player = game.players.reject(&:guesser?).first

        error = assert_raises(RuntimeError) do
          game.guesses.swap(player_id1: first_player.id, player_id2: 999_999)
        end

        assert_equal "Player 999999 not found", error.message
      end
    end
  end
end
