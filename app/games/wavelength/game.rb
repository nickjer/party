# frozen_string_literal: true

module Wavelength
  # Aggregate for a Wavelength game. Persistence goes through GameRepo.
  # Identity methods delegate to ::Game for Rails interop (dom_id, GlobalID).
  class Game
    WIN_SCORE = 10

    # Where the dial sits at the start of a round, before anyone moves it.
    CENTER = 50

    CLUE_LENGTH = LengthValidator.new(min: 1, max: 50, field: :clue)

    class << self
      def build(spectrum:, target:, starting_team: nil, id: nil)
        id ||= GameStore.generate_game_id
        team = starting_team || Team.red
        document = Document.new(
          status: Status.setup, starting_team: team, current_team: team,
          psychic_id: nil, clue: nil, spectrum:, target:, guess: CENTER,
          opponent_guess: nil, red_score: 0, blue_score: 0, winner: nil
        )
        new(id:, document:, players: [])
      end
    end

    # @dynamic id
    attr_reader :id

    def initialize(id:, document:, players:)
      @id = id
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

      @document = document.with(guess: position, status: Status.left_right)
      self
    end

    def guess_side(side:)
      raise "Game must be in left_right status" unless status.left_right?

      active_points = target.score_for(guess)
      opponent_correct = side.to_sym == target.side_of(guess)
      new_red, new_blue = award(active_points, opponent_correct)

      next_status, won = resolve(new_red, new_blue)
      @document = document.with(
        opponent_guess: side, red_score: new_red, blue_score: new_blue,
        status: next_status, winner: won ? leader(new_red, new_blue) : nil
      )
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
      @document = document.with(
        status: Status.setup, starting_team: team, current_team: team,
        psychic_id: nil, clue: nil, spectrum:, target:, guess: CENTER,
        opponent_guess: nil, red_score: 0, blue_score: 0, winner: nil
      )
      self
    end

    def document_json = document.to_json

    def model_name = ::Game.model_name
    def to_key = [id]
    def to_param = id

    def to_global_id(options = {})
      GlobalID.new(URI::GID.build(
        app: options.fetch(:app) { GlobalID.app },
        model_name: "Game",
        model_id: id,
        params: options.except(:app, :verifier, :for)
      ))
    end

    def to_gid_param(options = {}) = to_global_id(options).to_param

    private

    # @dynamic document
    attr_reader :document

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

    def resolve(new_red, new_blue)
      won = new_red >= WIN_SCORE || new_blue >= WIN_SCORE
      [won ? Status.completed : Status.reveal, won]
    end

    # v1: a tie resolves to the team that just scored (v2: sudden death).
    def leader(new_red, new_blue)
      return Team.red if new_red > new_blue
      return Team.blue if new_blue > new_red

      current_team
    end
  end
end
