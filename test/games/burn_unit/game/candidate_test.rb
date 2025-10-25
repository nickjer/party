# frozen_string_literal: true

require "test_helper"

module BurnUnit
  class Game
    class CandidateTest < ActiveSupport::TestCase
      test ".from sorts candidates by vote count descending then name" do
        game = build(:bu_polling_game,
          judge_name: "Judge",
          players: [
            { name: "Alice", vote_for: "Bob" },
            { name: "Bob", vote_for: "Bob" },
            { name: "Charlie", vote_for: "Alice" },
            { name: "David", vote_for: "Alice" }
          ])

        candidates = Candidate.from(game.players.select(&:playing?))

        # Alice has 2 votes, Bob has 2 votes (tie), Charlie 0, David 0, Judge 0
        # Tied winners sorted alphabetically: Alice, Bob
        # Then others alphabetically: Charlie, David, Judge
        assert_equal 5, candidates.size
        assert_equal "Alice", candidates[0].name.to_s
        assert_equal 2, candidates[0].vote_count
        assert_equal "Bob", candidates[1].name.to_s
        assert_equal 2, candidates[1].vote_count
      end

      test ".from returns candidates with no votes" do
        game = build(:bu_polling_game,
          judge_name: "Judge",
          player_names: %w[Alice Bob Charlie])

        candidates = Candidate.from(game.players.select(&:playing?))

        assert_equal 4, candidates.size
        candidates.each do |candidate|
          assert_equal 0, candidate.vote_count
          assert_not_predicate candidate, :winner?
        end
      end

      test ".from marks winners correctly when there is a clear winner" do
        game = build(:bu_polling_game,
          judge_name: "Judge",
          players: [
            { name: "Alice", vote_for: "Bob" },
            { name: "Bob", vote_for: "Bob" },
            { name: "Charlie", vote_for: "Alice" }
          ])

        candidates = Candidate.from(game.players.select(&:playing?))

        bob = candidates.find { |c| c.name.to_s == "Bob" }
        alice = candidates.find { |c| c.name.to_s == "Alice" }
        charlie = candidates.find { |c| c.name.to_s == "Charlie" }

        assert_predicate bob, :winner?
        assert_not_predicate alice, :winner?
        assert_not_predicate charlie, :winner?
      end

      test ".from marks multiple winners when there is a tie" do
        game = build(:bu_polling_game,
          judge_name: "Judge",
          players: [
            { name: "Alice", vote_for: "Bob" },
            { name: "Bob", vote_for: "Alice" },
            { name: "Charlie", vote_for: "David" },
            { name: "David" }
          ])

        candidates = Candidate.from(game.players.select(&:playing?))

        alice = candidates.find { |c| c.name.to_s == "Alice" }
        bob = candidates.find { |c| c.name.to_s == "Bob" }
        david = candidates.find { |c| c.name.to_s == "David" }

        # Alice and Bob each have 1 vote, David has 1 vote - all tied
        assert_predicate alice, :winner?
        assert_predicate bob, :winner?
        assert_predicate david, :winner?
      end

      test ".from returns voters sorted alphabetically by name" do
        game = build(:bu_polling_game,
          players: [
            { name: "Zara", vote_for: "Alice" },
            { name: "Bob", vote_for: "Alice" },
            { name: "Charlie", vote_for: "Alice" },
            { name: "Alice" }
          ])

        candidates = Candidate.from(game.players.select(&:playing?))
        alice = candidates.find { |c| c.name.to_s == "Alice" }

        voter_names = alice.voters.map(&:name).map(&:to_s)
        assert_equal %w[Bob Charlie Zara], voter_names
      end

      test "#id returns player id" do
        game = build(:bu_polling_game, player_names: %w[Alice])
        alice = game.players.first

        candidate = Candidate.new(player: alice, voters: [], winner: false)

        assert_equal alice.id, candidate.id
      end

      test "#name returns player name" do
        game = build(:bu_polling_game, player_names: %w[Alice])
        alice = game.players.first

        candidate = Candidate.new(player: alice, voters: [], winner: false)

        assert_equal alice.name, candidate.name
        assert_equal "Alice", candidate.name.to_s
      end

      test "#vote_count returns number of voters" do
        game = build(:bu_polling_game,
          players: [
            { name: "Bob", vote_for: "Alice" },
            { name: "Charlie", vote_for: "Alice" },
            { name: "Alice" }
          ])

        candidates = Candidate.from(game.players.select(&:playing?))
        alice = candidates.find { |c| c.name.to_s == "Alice" }

        assert_equal 2, alice.vote_count
      end

      test "#winner? returns true when candidate is winner" do
        game = build(:bu_polling_game, player_names: %w[Alice])
        alice = game.players.first

        candidate = Candidate.new(player: alice, voters: [], winner: true)

        assert_predicate candidate, :winner?
      end

      test "#winner? returns false when candidate is not winner" do
        game = build(:bu_polling_game, player_names: %w[Alice])
        alice = game.players.first

        candidate = Candidate.new(player: alice, voters: [], winner: false)

        assert_not_predicate candidate, :winner?
      end
    end
  end
end
