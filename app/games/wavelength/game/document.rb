# frozen_string_literal: true

module Wavelength
  class Game
    # Immutable value object for the parsed game document.
    class Document
      class << self
        def parse(hash)
          winner = hash.fetch(:winner)
          clue = hash.fetch(:clue)
          new(
            status: Status.parse(hash.fetch(:status)),
            starting_team: Team.parse(hash.fetch(:starting_team)),
            current_team: Team.parse(hash.fetch(:current_team)),
            psychic_id: hash.fetch(:psychic_id),
            clue: clue ? ::NormalizedString.new(clue) : nil,
            spectrum: Spectrum.parse(hash.fetch(:spectrum)),
            target: Target.new(position: hash.fetch(:target)),
            guess: hash.fetch(:guess),
            opponent_guess: hash.fetch(:opponent_guess),
            red_score: hash.fetch(:red_score),
            blue_score: hash.fetch(:blue_score),
            winner: winner ? Team.parse(winner) : nil
          )
        end
      end

      # @dynamic status, starting_team, current_team, psychic_id, clue,
      # @dynamic spectrum, target, guess, opponent_guess, red_score,
      # @dynamic blue_score, winner
      attr_reader :status, :starting_team, :current_team, :psychic_id, :clue,
        :spectrum, :target, :guess, :opponent_guess, :red_score, :blue_score,
        :winner

      def initialize(status:, starting_team:, current_team:, psychic_id:, clue:,
        spectrum:, target:, guess:, opponent_guess:, red_score:, blue_score:,
        winner:)
        @status = status
        @starting_team = starting_team
        @current_team = current_team
        @psychic_id = psychic_id
        @clue = clue
        @spectrum = spectrum
        @target = target
        @guess = guess
        @opponent_guess = opponent_guess
        @red_score = red_score
        @blue_score = blue_score
        @winner = winner
      end

      def with(status: @status, starting_team: @starting_team,
        current_team: @current_team, psychic_id: @psychic_id, clue: @clue,
        spectrum: @spectrum, target: @target, guess: @guess,
        opponent_guess: @opponent_guess, red_score: @red_score,
        blue_score: @blue_score, winner: @winner)
        self.class.new(status:, starting_team:, current_team:, psychic_id:,
          clue:, spectrum:, target:, guess:, opponent_guess:, red_score:,
          blue_score:, winner:)
      end

      def to_h
        {
          status: status.to_s,
          starting_team: starting_team.to_s,
          current_team: current_team.to_s,
          psychic_id:,
          clue: clue&.to_s,
          spectrum: spectrum.to_h,
          target: target.position,
          guess:,
          opponent_guess:,
          red_score:,
          blue_score:,
          winner: winner&.to_s
        }
      end

      def to_json(state = nil) = to_h.to_json(state)
    end
  end
end
