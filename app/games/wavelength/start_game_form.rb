# frozen_string_literal: true

module Wavelength
  # Readiness check for starting: each team needs at least two players (a
  # psychic plus at least one guesser). Status and role are the aggregate's
  # concern.
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
      return if game.players_on(team).size >= 2

      label = team.to_s.capitalize
      errors.add(:base, message: "#{label} team needs at least 2 players")
    end
  end
end
