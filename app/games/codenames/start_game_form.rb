# frozen_string_literal: true

module Codenames
  # Readiness check for starting: each team needs exactly one spymaster and at
  # least one operative. Status and role are the aggregate's concern.
  class StartGameForm
    # @dynamic errors
    attr_reader :errors

    def initialize(game:)
      @game = game
      @errors = Errors.new
    end

    def valid?
      [Team.red, Team.blue].each { |team| validate_team(team) }

      errors.empty?
    end

    private

    # @dynamic game
    attr_reader :game

    def validate_team(team)
      members = game.players_on(team)
      label = team.to_s.capitalize

      unless members.one?(&:spymaster?)
        errors.add(:base, message: "#{label} team needs one spymaster")
      end
      return if members.any?(&:operative?)

      errors.add(:base, message: "#{label} team needs an operative")
    end
  end
end
