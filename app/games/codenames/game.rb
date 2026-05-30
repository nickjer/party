# frozen_string_literal: true

module Codenames
  # Aggregate for a Codenames game. Persistence goes through GameRepo.
  # Identity methods delegate to ::Game for Rails interop (dom_id, GlobalID).
  class Game
    class << self
      def build(words:, starting_team: nil, id: nil)
        id ||= GameRepo.generate_id
        team = starting_team || [Team.red, Team.blue].sample #: Team
        document = Document.new(
          status: Status.setup,
          starting_team: team,
          current_team: team,
          winner: nil,
          board: Board.generate(words:, starting_team: team)
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

    def add_player(user_id:, name:, team: nil, spymaster: false)
      raise "Player already exists for user" if player_for(user_id)

      player = Player.build(game_id: id, user_id:, name:, team:, spymaster:)
      @players << player
      player
    end

    def blue_team = players_on(Team.blue)

    def board = document.board

    def current_team = document.current_team

    def find_player(id)
      players.find { |player| player.id == id } || raise("Player not found")
    end

    def operatives = players.select(&:operative?)

    def player_for(user_id)
      players.find { |player| player.user_id == user_id }
    end

    def player_for!(user_id)
      player_for(user_id) ||
        raise(ActiveRecord::RecordNotFound, "Couldn't find Player")
    end

    def players = @players.sort

    def players_on(team) = players.select { |player| player.team == team }

    def red_team = players_on(Team.red)

    def spymaster_for(team) = players_on(team).find(&:spymaster?)

    def spymasters = players.select(&:spymaster?)

    def starting_team = document.starting_team

    def status = document.status

    def winner = document.winner

    def join_team(player:, team:, spymaster:)
      player.team = team
      player.spymaster = spymaster
      self
    end

    def start_game
      raise "Game must be in setup status" unless status.setup?

      @document = document.with(status: Status.playing)
      self
    end

    def reveal(index:)
      raise "Game must be in playing status" unless status.playing?

      card = board.card(index)
      raise "Card already revealed" if card.revealed?

      new_board = board.reveal(index)
      @document =
        if card.identity.assassin?
          document.with(board: new_board, status: Status.completed,
            winner: current_team.opponent)
        elsif new_board.all_revealed?(Team.red)
          document.with(board: new_board, status: Status.completed,
            winner: Team.red)
        elsif new_board.all_revealed?(Team.blue)
          document.with(board: new_board, status: Status.completed,
            winner: Team.blue)
        elsif card.identity.team == current_team
          document.with(board: new_board) # correct guess: keep guessing
        else
          document.with(board: new_board, current_team: current_team.opponent)
        end
      self
    end

    def pass_turn
      raise "Game must be in playing status" unless status.playing?

      @document = document.with(current_team: current_team.opponent)
      self
    end

    def start_new_game(words:, starting_team: nil)
      raise "Game must be in completed status" unless status.completed?

      team = starting_team || [Team.red, Team.blue].sample #: Team
      @document = document.with(
        status: Status.setup,
        starting_team: team,
        current_team: team,
        winner: nil,
        board: Board.generate(words:, starting_team: team)
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
  end
end
