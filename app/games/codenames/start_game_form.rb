# frozen_string_literal: true

module Codenames
  # Form object for validating the transition from setup to playing. Each team
  # needs exactly one spymaster and at least one operative.
  class StartGameForm
    # @dynamic errors
    attr_reader :errors

    def initialize(game:)
      @game = game
      @errors = Errors.new
    end

    def valid?
      unless game.status.setup?
        errors.add(:base, message: "Game has already started")
      end

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
