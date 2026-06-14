# frozen_string_literal: true

module Wavelength
  # Validates a player picking a team. Teams lock once the game leaves setup,
  # except a teamless mid-game joiner may still pick a side.
  class JoinTeamForm
    # @dynamic team
    attr_reader :team
    # @dynamic errors
    attr_reader :errors

    def initialize(game:, current_player:, team: nil)
      @game = game
      @current_player = current_player
      @team = parse_team(team)
      @errors = Errors.new
    end

    def valid?
      if team.nil?
        errors.add(:team, message: "must be red or blue")
        return false
      end

      validate_status
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
      elsif !game.status.setup? && current_player.team
        errors.add(:base, message: "Teams are locked once the game starts")
      end
    end
  end
end
