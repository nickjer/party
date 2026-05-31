# frozen_string_literal: true

module Codenames
  # Form object for validating a player picking a team and role. Enforces one
  # spymaster per team, and locks roles/switching once the game is playing.
  class JoinTeamForm
    # @dynamic team
    attr_reader :team

    # @dynamic spymaster
    attr_reader :spymaster

    # @dynamic errors
    attr_reader :errors

    def initialize(game:, current_player:, team: nil, spymaster: false)
      @game = game
      @current_player = current_player
      @team = parse_team(team)
      @spymaster = [true, "true", "1"].include?(spymaster)
      @errors = Errors.new
    end

    def valid?
      selected_team = team
      if selected_team.nil?
        errors.add(:team, message: "must be red or blue")
        return false
      end

      validate_status
      validate_spymaster_seat(selected_team) if spymaster

      errors.empty?
    end

    private

    # @dynamic game, current_player
    attr_reader :game, :current_player

    def parse_team(value)
      Team.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    def validate_status
      if game.status.completed?
        errors.add(:base, message: "Game is over")
      elsif game.status.playing?
        validate_midgame_join
      end
    end

    def validate_midgame_join
      if spymaster
        errors.add(:spymaster,
          message: "roles are locked once the game starts")
      end
      return unless current_player.team

      errors.add(:base, message: "Teams are locked once the game starts")
    end

    def validate_spymaster_seat(selected_team)
      existing = game.spymaster_for(selected_team)
      return unless existing && existing != current_player

      errors.add(:spymaster,
        message: "#{selected_team} team already has a spymaster")
    end
  end
end
