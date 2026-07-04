# frozen_string_literal: true

require "test_helper"

module Codenames
  class GameTest < ActiveSupport::TestCase
    test ".build creates a setup game with a 25-card board" do
      game = Game.build(words: Words.instance.sample,
        starting_team: Team.red)

      assert_predicate game.status, :setup?
      assert_equal 25, game.board.cards.size
      assert_equal Team.red, game.starting_team
      assert_nil game.clue
      assert_equal 0, game.guesses_made
    end

    test ".build sets current_team to the starting team" do
      game = Game.build(words: Words.instance.sample,
        starting_team: Team.blue)

      assert_equal Team.blue, game.current_team
    end

    test ".build defaults the starting team to red" do
      game = Game.build(words: Words.instance.sample)

      assert_equal Team.red, game.starting_team
    end

    test "#add_player adds a teamless player by default" do
      game = build(:cn_game)

      player = game.add_player(user_id: "u1", name: PlayerName.parse("Alice"))

      assert_nil player.team
      assert_not_predicate player, :spymaster?
      assert_includes game.players, player
    end

    test "#add_player raises when the user already has a player" do
      game = build(:cn_game)
      game.add_player(user_id: "u1", name: PlayerName.parse("Alice"))

      assert_raises(RuntimeError) do
        game.add_player(user_id: "u1", name: PlayerName.parse("Bob"))
      end
    end

    test "#join_team assigns the team and spymaster role" do
      game = build(:cn_game)
      player = game.add_player(user_id: "u1", name: PlayerName.parse("Alice"))

      game.join_team(player:, team: Team.red, spymaster: true)

      assert_equal Team.red, player.team
      assert_predicate player, :spymaster?
    end

    test "#spymaster_for finds the team's spymaster" do
      game = build(:cn_playing_game)

      assert_equal "RedSpy", game.spymaster_for(Team.red).name.to_s
      assert_equal "BlueSpy", game.spymaster_for(Team.blue).name.to_s
    end

    test "#operatives excludes spymasters and teamless players" do
      game = build(:cn_playing_game)

      assert_equal %w[BlueOp RedOp], game.operatives.map { |p|
        p.name.to_s
      }.sort
    end

    test "#start_game transitions setup to playing" do
      game = build(:cn_game, :with_teams)

      game.start_game

      assert_predicate game.status, :playing?
    end

    test "#start_game raises unless in setup" do
      game = build(:cn_playing_game)

      assert_raises(RuntimeError) { game.start_game }
    end

    test "#submit_clue stores the clue and resets the guess count" do
      game = build(:cn_playing_game)

      game.submit_clue(word: NormalizedString.new("Ocean"), number: 2)

      clue = game.clue
      assert_equal "Ocean", clue.word.to_s
      assert_equal 2, clue.number
      assert_equal 0, game.guesses_made
    end

    test "#submit_clue raises unless playing" do
      game = build(:cn_game, :with_teams)

      assert_raises(RuntimeError) do
        game.submit_clue(word: NormalizedString.new("Ocean"), number: 2)
      end
    end

    test "#submit_clue raises when a clue is already submitted" do
      game = build(:cn_guessing_game)

      assert_raises(RuntimeError) do
        game.submit_clue(word: NormalizedString.new("Ocean"), number: 2)
      end
    end

    test "#submit_clue raises when the word is too long" do
      game = build(:cn_playing_game)

      assert_raises(ArgumentError) do
        game.submit_clue(word: NormalizedString.new("x" * 51), number: 2)
      end
    end

    test "#guesses_remaining is nil before a clue is submitted" do
      game = build(:cn_playing_game)

      assert_nil game.guesses_remaining
    end

    test "#guesses_remaining is nil for an unlimited clue" do
      game = build(:cn_guessing_game) # unlimited by default

      assert_nil game.guesses_remaining
    end

    test "#guesses_remaining subtracts the guesses made from the limit" do
      game = build(:cn_guessing_game, clue_number: 2) # 2 + 1 bonus = 3

      assert_equal 3, game.guesses_remaining

      game.reveal(index: red_agent_index(game))

      assert_equal 2, game.guesses_remaining
    end

    test "#reveal of own agent keeps the turn and counts the guess" do
      game = build(:cn_guessing_game) # red starts

      game.reveal(index: red_agent_index(game))

      assert_equal Team.red, game.current_team
      assert_predicate game.status, :playing?
      assert_equal 1, game.guesses_made
    end

    test "#reveal of enemy agent ends the turn and clears the clue" do
      game = build(:cn_guessing_game)

      game.reveal(index: blue_agent_index(game))

      assert_equal Team.blue, game.current_team
      assert_nil game.clue
      assert_equal 0, game.guesses_made
    end

    test "#reveal of bystander ends the turn" do
      game = build(:cn_guessing_game)
      bystander = index_of(game) { |card| card.identity.bystander? }

      game.reveal(index: bystander)

      assert_equal Team.blue, game.current_team
      assert_predicate game.status, :playing?
      assert_nil game.clue
    end

    test "#reveal ends the turn when the clue's guesses are used up" do
      game = build(:cn_guessing_game, clue_number: 1) # 1 + 1 bonus = 2 guesses
      first, second = red_agent_indexes(game)

      game.reveal(index: first)

      assert_equal Team.red, game.current_team
      assert_equal 1, game.guesses_made

      game.reveal(index: second)

      assert_equal Team.blue, game.current_team
      assert_nil game.clue
      assert_equal 0, game.guesses_made
    end

    test "#reveal never ends the turn by count for a zero clue" do
      game = build(:cn_guessing_game, clue_number: 0)

      red_agent_indexes(game).first(3).each { |index| game.reveal(index:) }

      assert_equal Team.red, game.current_team
      assert_equal 3, game.guesses_made
    end

    test "#reveal never ends the turn by count for an unlimited clue" do
      game = build(:cn_guessing_game) # unlimited by default

      red_agent_indexes(game).first(3).each { |index| game.reveal(index:) }

      assert_equal Team.red, game.current_team
      assert_equal 3, game.guesses_made
    end

    test "#reveal of assassin ends the game and the other team wins" do
      game = build(:cn_guessing_game)
      assassin = index_of(game) { |card| card.identity.assassin? }

      game.reveal(index: assassin)

      assert_predicate game.status, :completed?
      assert_equal Team.blue, game.winner
      assert_nil game.clue
      assert_equal 0, game.guesses_made
    end

    test "#reveal of the last agent wins for that team" do
      game = build(:cn_guessing_game)
      game.board.cards.each_with_index do |card, index|
        next if card.identity.team != Team.red || game.status.completed?

        game.reveal(index:)
      end

      assert_predicate game.status, :completed?
      assert_equal Team.red, game.winner
    end

    test "#reveal of the last agent wins for the blue team" do
      game = build(:cn_guessing_game, starting_team: Team.blue)
      game.board.cards.each_with_index do |card, index|
        next if card.identity.team != Team.blue || game.status.completed?

        game.reveal(index:)
      end

      assert_predicate game.status, :completed?
      assert_equal Team.blue, game.winner
    end

    test "#reveal that wins on the last allowed guess completes the game" do
      game = build(:cn_guessing_game, clue_number: 8) # limit 9 = all agents

      red_agent_indexes(game).each { |index| game.reveal(index:) }

      assert_predicate game.status, :completed?
      assert_equal Team.red, game.winner
      assert_nil game.clue
      assert_equal 0, game.guesses_made
    end

    test "#reveal raises unless playing" do
      game = build(:cn_game, :with_teams)

      assert_raises(RuntimeError) { game.reveal(index: 0) }
    end

    test "#reveal raises when no clue is submitted" do
      game = build(:cn_playing_game)

      assert_raises(RuntimeError) { game.reveal(index: 0) }
    end

    test "#reveal raises when the card is already revealed" do
      game = build(:cn_guessing_game)
      index = red_agent_index(game)
      game.reveal(index:)

      assert_raises(RuntimeError) { game.reveal(index:) }
    end

    test "#pass_turn flips the current team and clears the clue" do
      game = build(:cn_guessing_game)
      game.reveal(index: red_agent_index(game))

      game.pass_turn

      assert_equal Team.blue, game.current_team
      assert_nil game.clue
      assert_equal 0, game.guesses_made
    end

    test "#pass_turn raises unless playing" do
      game = build(:cn_game, :with_teams)

      assert_raises(RuntimeError) { game.pass_turn }
    end

    test "#pass_turn raises when no clue is submitted" do
      game = build(:cn_playing_game)

      assert_raises(RuntimeError) { game.pass_turn }
    end

    test "#pass_turn raises before the team has guessed" do
      game = build(:cn_guessing_game)

      assert_raises(RuntimeError) { game.pass_turn }
    end

    test "#start_new_game regenerates the board and keeps players" do
      game = build(:cn_completed_game)
      old_words = game.board.cards.map(&:word)

      game.start_new_game(words: Words.instance.sample)

      assert_predicate game.status, :setup?
      assert_nil game.winner
      assert_nil game.clue
      assert_equal 0, game.guesses_made
      assert_equal 4, game.players.size
      assert_not_equal old_words, game.board.cards.map(&:word)
    end

    test "#start_new_game switches the starting team to the opponent" do
      game = build(:cn_completed_game, starting_team: Team.red)

      game.start_new_game(words: Words.instance.sample)

      assert_equal Team.blue, game.starting_team
      assert_equal Team.blue, game.current_team
    end

    test "#start_new_game honors an explicit starting team" do
      game = build(:cn_completed_game, starting_team: Team.red)

      game.start_new_game(words: Words.instance.sample, starting_team: Team.red)

      assert_equal Team.red, game.starting_team
      assert_equal Team.red, game.current_team
    end

    test "#start_new_game raises unless completed" do
      game = build(:cn_playing_game)

      assert_raises(RuntimeError) do
        game.start_new_game(words: Words.instance.sample)
      end
    end

    test "#to_global_id builds a GlobalID for the game" do
      game = build(:cn_game)

      gid = game.to_global_id

      assert_equal "Game", gid.model_name
      assert_equal game.id, gid.model_id
    end

    test "persists and reloads through the repo" do
      game = create(:cn_playing_game)

      reloaded = reload(game:)

      assert_predicate reloaded.status, :playing?
      assert_equal 4, reloaded.players.size
      assert_equal 9, reloaded.board.total_for(Team.red)
    end

    test "persists the clue through the repo" do
      game = create(:cn_guessing_game, clue_number: 3)

      reloaded = reload(game:)

      clue = reloaded.clue
      assert_equal "Hint", clue.word.to_s
      assert_equal 3, clue.number
      assert_equal 0, reloaded.guesses_made
    end

    private

    def index_of(game, &) = game.board.cards.index(&)

    def red_agent_index(game)
      index_of(game) { |card| card.identity.team == Team.red }
    end

    def red_agent_indexes(game)
      game.board.cards.each_with_index
        .select { |card, _index| card.identity.team == Team.red }
        .map { |_card, index| index }
    end

    def blue_agent_index(game)
      index_of(game) { |card| card.identity.team == Team.blue }
    end
  end
end
