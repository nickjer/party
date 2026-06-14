# frozen_string_literal: true

require "test_helper"

module Wavelength
  class GameTest < ActiveSupport::TestCase
    test ".build starts in setup with the second team's head start" do
      game = build(:wl_game) # red starts

      assert_predicate game.status, :setup?
      assert_equal Team.red, game.current_team
      assert_equal Team.red, game.starting_team
      assert_equal 0, game.score_for(Team.red)
      assert_equal 1, game.score_for(Team.blue) # second team's head start
      assert_nil game.psychic
    end

    test ".build accepts a custom starting team" do
      game = build(:wl_game, starting_team: Team.blue)

      assert_equal Team.blue, game.current_team
      assert_equal Team.blue, game.starting_team
    end

    test "#add_player adds a teamless player by default" do
      game = build(:wl_game)

      player = game.add_player(user_id: "u1", name: PlayerName.parse("Alice"))

      assert_nil player.team
      assert_includes game.players, player
    end

    test "#add_player raises when the user already has a player" do
      game = build(:wl_game)
      game.add_player(user_id: "u1", name: PlayerName.parse("Alice"))

      error = assert_raises(RuntimeError) do
        game.add_player(user_id: "u1", name: PlayerName.parse("Bob"))
      end

      assert_match(/already exists/, error.message)
    end

    test "#find_player raises when the id is unknown" do
      game = build(:wl_game)

      assert_raises(RuntimeError) { game.find_player("nope") }
    end

    test "#player_for! raises when the user is unknown" do
      game = build(:wl_game)

      assert_raises(ActiveRecord::RecordNotFound) { game.player_for!("nope") }
    end

    test "#join_team assigns the player's team" do
      game = build(:wl_game)
      player = game.add_player(user_id: "u1", name: PlayerName.parse("Alice"))

      game.join_team(player:, team: Team.blue)

      assert_equal Team.blue, player.team
    end

    test "#players_on filters by team" do
      game = build(:wl_game, :with_teams)
      red = game.players_on(Team.red)

      assert_equal 2, red.size
      assert(red.all? { |player| player.team == Team.red })
    end

    test "#start_game moves to the clue phase with the claimer as psychic" do
      game = build(:wl_game, :with_teams) # red starts
      claimer = game.players_on(Team.red).last

      game.start_game(psychic: claimer)

      assert_predicate game.status, :clue?
      assert_nil game.clue
      assert_equal claimer, game.psychic
    end

    test "#start_game raises unless in setup" do
      game = build(:wl_guessing_game)
      psychic = game.psychic

      assert_raises(RuntimeError) { game.start_game(psychic:) }
    end

    test "#start_game raises when the psychic is not on the starting team" do
      game = build(:wl_game, :with_teams) # red starts
      blue = game.players_on(Team.blue).first

      assert_raises(RuntimeError) { game.start_game(psychic: blue) }
    end

    test "#submit_clue stores the clue and moves to guessing" do
      game = build(:wl_clue_game)

      game.submit_clue(text: NormalizedString.new("Banana"))

      assert_predicate game.status, :guessing?
      assert_equal "Banana", game.clue.to_s
    end

    test "#submit_clue stores the normalized (squished) clue" do
      game = build(:wl_clue_game)

      game.submit_clue(text: NormalizedString.new("  Banana   split  "))

      assert_equal "Banana split", game.clue.to_s
    end

    test "#submit_clue raises unless in the clue phase" do
      game = build(:wl_guessing_game)

      assert_raises(RuntimeError) do
        game.submit_clue(text: NormalizedString.new("Banana"))
      end
    end

    test "#submit_clue raises for a blank clue" do
      game = build(:wl_clue_game)

      assert_raises(ArgumentError) do
        game.submit_clue(text: NormalizedString.new("   "))
      end
    end

    test "#submit_clue raises for a clue that is too long" do
      game = build(:wl_clue_game)

      assert_raises(ArgumentError) do
        game.submit_clue(text: NormalizedString.new("x" * 51))
      end
    end

    test "#psychic? is true for the assigned psychic and false otherwise" do
      game = build(:wl_guessing_game)

      assert game.psychic?(game.psychic)
      assert_not game.psychic?(game.guessers.first)
    end

    test "#guessers are the active team minus the psychic" do
      game = build(:wl_guessing_game) # red active

      assert_equal 1, game.guessers.size
      assert(game.guessers.all? { |player| player.team == Team.red })
      assert_not_includes game.guessers, game.psychic
    end

    test "#suggested_psychic picks the starting team's least-used psychic" do
      game = build(:wl_game, :with_teams) # red starts, all counts zero

      assert_includes game.players_on(Team.red), game.suggested_psychic
    end

    test "#suggested_psychic picks the up team between rounds" do
      game = build(:wl_reveal_game) # red just played, blue is up

      assert_includes game.players_on(Team.blue), game.suggested_psychic
    end

    test "#move_dial slides the dial and stays in guessing" do
      game = build(:wl_guessing_game)

      game.move_dial(position: 30)

      assert_predicate game.status, :guessing?
      assert_equal 30, game.guess
    end

    test "#move_dial raises unless in guessing" do
      game = build(:wl_reveal_game)

      assert_raises(RuntimeError) { game.move_dial(position: 30) }
    end

    test "#lock_guess on a near-miss stores the guess and moves to left_right" do
      game = build(:wl_guessing_game, target_position: 50) # red active

      game.lock_guess(position: 73) # 23 off the target -> no bullseye

      assert_predicate game.status, :left_right?
      assert_equal 73, game.guess
    end

    test "#lock_guess on a bullseye scores the active team and skips reveal" do
      game = build(:wl_guessing_game, target_position: 50) # red active

      game.lock_guess(position: 50) # dead-center bullseye

      assert_equal 4, game.score_for(Team.red)
      assert_equal 1, game.score_for(Team.blue) # head start only; can't score
      assert_predicate game.status, :reveal?
      assert_nil game.opponent_guess # the opponent never gets to guess
    end

    test "#lock_guess treats the whole 4-point wedge as a bullseye" do
      game = build(:wl_guessing_game, target_position: 50) # red active

      game.lock_guess(position: 52) # off-center but inside the 4-point wedge

      assert_predicate game.status, :reveal? # still skips the opponent
      assert_equal 4, game.score_for(Team.red)
      assert_equal 1, game.score_for(Team.blue) # head start only; can't score
    end

    test "#lock_guess on a bullseye scores the blue active team" do
      game = build(:wl_guessing_game, starting_team: Team.blue,
        target_position: 50)

      game.lock_guess(position: 50) # bullseye

      assert_equal 4, game.score_for(Team.blue)
      assert_predicate game.status, :reveal?
    end

    test "#lock_guess completes the game when a team reaches the win score" do
      game = build(:wl_completed_game)

      assert_predicate game.status, :completed?
      assert_equal Team.red, game.winner
    end

    test "#lock_guess lets the blue starting team win" do
      game = build(:wl_completed_game, starting_team: Team.blue)

      assert_equal Team.blue, game.winner
    end

    test "#lock_guess raises unless in guessing" do
      game = build(:wl_game, :with_teams)

      assert_raises(RuntimeError) { game.lock_guess(position: 50) }
    end

    test "#guess_side gives the opponent a point for a correct side" do
      game = build(:wl_guessing_game, target_position: 70) # red active
      game.lock_guess(position: 50) # near-miss; target is RIGHT of 50

      game.guess_side(side: "right") # blue (opponent) correct

      assert_equal 2, game.score_for(Team.blue) # 1 head start + 1 steal
      assert_predicate game.status, :reveal?
      assert_equal "right", game.opponent_guess
    end

    test "#guess_side gives the opponent nothing for a wrong side" do
      game = build(:wl_guessing_game, target_position: 70) # red active
      game.lock_guess(position: 50) # target is RIGHT of 50

      game.guess_side(side: "left") # blue (opponent) wrong

      assert_equal 1, game.score_for(Team.blue) # head start only, wrong side
    end

    test "#guess_side gives the red opponent a point when blue is active" do
      game = build(:wl_guessing_game, starting_team: Team.blue,
        target_position: 70)
      game.lock_guess(position: 50) # target is RIGHT of 50

      game.guess_side(side: "right") # red (opponent) correct

      assert_equal 2, game.score_for(Team.red) # 1 head start + 1 steal
    end

    test "#guess_side resolves a win-score tie to the team that just scored" do
      # Red 7, blue 9. Red locks a near-miss (3 points -> red 10) just left of
      # the target, so blue guesses "right" correctly (blue -> 10). The 10-10
      # tie resolves to the active (current) team: red.
      document = Game::Document.new(
        status: Game::Status.left_right, starting_team: Team.red,
        current_team: Team.red, psychic_id: "p1", clue: "Clue",
        spectrum: Game::Spectrum.new(left: "A", right: "B"),
        target: Game::Target.new(position: 55), guess: 50,
        opponent_guess: nil, red_score: 7, blue_score: 9, winner: nil
      )
      game = Game.new(id: "g1", document:, players: [])

      game.guess_side(side: "right")

      assert_equal 10, game.score_for(Team.red)
      assert_equal 10, game.score_for(Team.blue)
      assert_equal Team.red, game.winner
    end

    test "#guess_side raises unless in left_right" do
      game = build(:wl_guessing_game)

      assert_raises(RuntimeError) { game.guess_side(side: "left") }
    end

    test "#start_new_round flips the team and the claiming player is psychic" do
      game = build(:wl_reveal_game) # red just played, status reveal
      claimer = game.players_on(Team.blue).last

      game.start_new_round(psychic: claimer,
        spectrum: Spectrums.instance.sample,
        target: Game::Target.new(position: 50))

      assert_predicate game.status, :clue?
      assert_equal Team.blue, game.current_team
      assert_equal claimer, game.psychic
    end

    test "#start_new_round recenters the dial and clears the clue" do
      game = build(:wl_reveal_game)
      claimer = game.players_on(Team.blue).first

      game.start_new_round(psychic: claimer,
        spectrum: Spectrums.instance.sample,
        target: Game::Target.new(position: 12))

      assert_equal Game::CENTER, game.guess
      assert_nil game.opponent_guess
      assert_nil game.clue
      assert_equal 12, game.target.position
    end

    test "#start_new_round raises when the psychic is not on the up team" do
      game = build(:wl_reveal_game) # red just played, blue is up
      red = game.players_on(Team.red).first

      assert_raises(RuntimeError) do
        game.start_new_round(psychic: red, spectrum: Spectrums.instance.sample,
          target: Game::Target.new(position: 50))
      end
    end

    test "#start_new_round raises unless in reveal" do
      game = build(:wl_guessing_game)
      blue = game.players_on(Team.blue).first

      assert_raises(RuntimeError) do
        game.start_new_round(psychic: blue, spectrum: Spectrums.instance.sample,
          target: Game::Target.new(position: 50))
      end
    end

    test "#start_new_game flips the starting team and resets with head start" do
      game = build(:wl_completed_game) # red started and won

      game.start_new_game(spectrum: Spectrums.instance.sample,
        target: Game::Target.new(position: 50))

      assert_predicate game.status, :setup?
      assert_equal Team.blue, game.starting_team
      assert_equal 0, game.score_for(Team.blue) # new starting team
      assert_equal 1, game.score_for(Team.red)  # second team's head start
      assert_equal 4, game.players.size
    end

    test "#start_new_game accepts an explicit starting team" do
      game = build(:wl_completed_game)

      game.start_new_game(spectrum: Spectrums.instance.sample,
        target: Game::Target.new(position: 50), starting_team: Team.red)

      assert_equal Team.red, game.starting_team
    end

    test "#start_new_game raises unless completed" do
      game = build(:wl_guessing_game)

      assert_raises(RuntimeError) do
        game.start_new_game(spectrum: Spectrums.instance.sample,
          target: Game::Target.new(position: 50))
      end
    end

    test "#to_global_id builds a Game GID" do
      game = Game.build(spectrum: Game::Spectrum.new(left: "A", right: "B"),
        target: Game::Target.new(position: 50), id: "g1")

      assert_equal "Game", game.to_global_id.model_name
      assert_equal "g1", game.to_global_id.model_id
    end

    test "#document_json survives a repo round-trip" do
      game = create(:wl_reveal_game)

      reloaded = GameRepo.find(game.id)

      assert_equal game.id, reloaded.id
      assert_predicate reloaded.status, :reveal?
      assert_equal game.players.map(&:id).sort, reloaded.players.map(&:id).sort
      assert_equal game.psychic.id, reloaded.psychic.id
    end
  end
end
