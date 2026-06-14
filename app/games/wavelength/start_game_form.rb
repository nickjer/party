# frozen_string_literal: true

module Wavelength
  # Validates setup -> guessing: each team needs at least two players
  # (a psychic plus at least one guesser).
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
      return if game.players_on(team).size >= 2

      label = team.to_s.capitalize
      errors.add(:base, message: "#{label} team needs at least 2 players")
    end
  end
end
