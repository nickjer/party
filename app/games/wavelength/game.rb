# frozen_string_literal: true

module Wavelength
  # Aggregate for a Wavelength game. Persistence goes through GameRepo.
  # Identity methods delegate to GlobalIdentity for Rails interop.
  class Game
    WIN_SCORE = 10

    # Where the dial sits at the start of a round, before anyone moves it.
    CENTER = 50

    CLUE_LENGTH = LengthValidator.new(min: 1, max: 50, field: :clue)

    class << self
      def build(spectrum:, target:, starting_team: nil, id: nil)
        id ||= GameStore.generate_game_id
        team = starting_team || Team.red
        new(id:, players: [],
          document: fresh_document(spectrum:, target:, starting_team: team))
      end

      # A setup-phase document for a brand-new board: dial centered, no psychic
      # or clue, and a 1-point head start for the team that goes second.
      def fresh_document(spectrum:, target:, starting_team:)
        Document.new(
          status: Status.setup, starting_team:, current_team: starting_team,
          psychic_id: nil, clue: nil, spectrum:, target:, guess: CENTER,
          opponent_guess: nil, red_score: starting_team.red? ? 0 : 1,
          blue_score: starting_team.blue? ? 0 : 1, winner: nil
        )
      end
    end

    # @dynamic id
    attr_reader :id

    def initialize(id:, document:, players:)
      @id = id
      @identity = GlobalIdentity.new(model: ::Game, id:)
      @document = document
      @players = players
    end

    def add_player(user_id:, name:, team: nil)
      raise "Player already exists for user" if player_for(user_id)

      player = Player.build(game_id: id, user_id:, name:, team:)
      @players << player
      player
    end

    def blue_team = players_on(Team.blue)
    def clue = document.clue
    def current_team = document.current_team
    def guess = document.guess
    def opponent_guess = document.opponent_guess
    def red_team = players_on(Team.red)
    def spectrum = document.spectrum
    def starting_team = document.starting_team
    def status = document.status
    def target = document.target
    def winner = document.winner

    def find_player(id)
      players.find { |player| player.id == id } || raise("Player not found")
    end

    def player_for(user_id)
      players.find { |player| player.user_id == user_id }
    end

    def player_for!(user_id)
      player_for(user_id) ||
        raise(ActiveRecord::RecordNotFound, "Couldn't find Player")
    end

    def players = @players.sort
    def players_on(team) = players.select { |player| player.team == team }

    def psychic = document.psychic_id ? find_player(document.psychic_id) : nil
    def psychic?(player) = player.id == document.psychic_id

    # Active-team players who may move/lock the dial (everyone but the psychic).
    def guessers
      players_on(current_team).reject { |player| psychic?(player) }
    end

    # The up-team member who's been psychic least; the suggested next psychic.
    def suggested_psychic
      team = status.reveal? ? current_team.opponent : current_team
      players_on(team).min_by(&:psychic_count)
    end

    def score_for(team) = team.red? ? document.red_score : document.blue_score

    def join_team(player:, team:)
      player.team = team
      self
    end

    def start_game(psychic:)
      raise "Game must be in setup status" unless status.setup?

      become_psychic(psychic, on: starting_team)
      @document = document.with(status: Status.clue, psychic_id: psychic.id)
      self
    end

    def submit_clue(text:)
      raise "Game must be in clue status" unless status.clue?

      CLUE_LENGTH.validate!(text)
      @document = document.with(clue: text, status: Status.guessing)
      self
    end

    def move_dial(position:)
      raise "Game must be in guessing status" unless status.guessing?

      @document = document.with(guess: position)
      self
    end

    def lock_guess(position:)
      raise "Game must be in guessing status" unless status.guessing?

      @document = document.with(guess: position)
      # A bullseye ends the round outright: a perfect lock leaves the opponent
      # no side to catch, so we settle now and skip the left/right step.
      if target.bullseye?(position)
        settle_round(opponent_guess: nil)
      else
        @document = document.with(status: Status.left_right)
      end
      self
    end

    def guess_side(side:)
      raise "Game must be in left_right status" unless status.left_right?

      settle_round(opponent_guess: side)
      self
    end

    def start_new_round(psychic:, spectrum:, target:)
      raise "Game must be in reveal status" unless status.reveal?

      next_team = current_team.opponent
      become_psychic(psychic, on: next_team)
      @document = document.with(
        status: Status.clue, current_team: next_team,
        psychic_id: psychic.id, clue: nil, spectrum:, target:, guess: CENTER,
        opponent_guess: nil
      )
      self
    end

    def start_new_game(spectrum:, target:, starting_team: nil)
      raise "Game must be in completed status" unless status.completed?

      team = starting_team || document.starting_team.opponent
      @document = self.class.fresh_document(spectrum:, target:,
        starting_team: team)
      self
    end

    def document_json = document.to_json

    def model_name = identity.model_name
    def to_key = identity.to_key
    def to_param = identity.to_param
    def to_global_id(options = {}) = identity.to_global_id(options)
    def to_gid_param(options = {}) = identity.to_gid_param(options)

    private

    # @dynamic document, identity
    attr_reader :document, :identity

    # Marks the claiming player as the psychic; they must be on the up team.
    def become_psychic(player, on:)
      raise "Psychic must be on the #{on} team" if player.team != on

      player.increment_psychic_count
    end

    def award(active_points, opponent_correct)
      new_red = document.red_score
      new_blue = document.blue_score
      if current_team.red?
        new_red += active_points
        new_blue += 1 if opponent_correct
      else
        new_blue += active_points
        new_red += 1 if opponent_correct
      end
      [new_red, new_blue]
    end

    # Scores the locked guess (plus the opponent's optional left/right call),
    # then reveals or completes the round on a win.
    def settle_round(opponent_guess:)
      active_points = target.score_for(guess)
      opponent_correct = opponent_guess&.to_sym == target.side_of(guess)
      new_red, new_blue = award(active_points, opponent_correct)
      won = new_red >= WIN_SCORE || new_blue >= WIN_SCORE
      @document = document.with(
        opponent_guess:, red_score: new_red, blue_score: new_blue,
        status: won ? Status.completed : Status.reveal,
        winner: won ? leader(new_red, new_blue) : nil
      )
    end

    # v1: a tie resolves to the team that just scored (v2: sudden death).
    def leader(new_red, new_blue)
      return Team.red if new_red > new_blue
      return Team.blue if new_blue > new_red

      current_team
    end
  end
end
