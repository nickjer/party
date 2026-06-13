# frozen_string_literal: true

module Wavelength
  class Player
    # Immutable value object: the player's team (nil until chosen) and how many
    # times they've been psychic (drives fair rotation).
    class Document
      class << self
        def parse(hash)
          team = hash.fetch(:team)
          new(
            team: team ? Team.parse(team) : nil,
            psychic_count: hash.fetch(:psychic_count)
          )
        end
      end

      # @dynamic team, psychic_count
      attr_reader :team, :psychic_count

      def initialize(team:, psychic_count:)
        @team = team
        @psychic_count = psychic_count
      end

      def with(team: @team, psychic_count: @psychic_count)
        self.class.new(team:, psychic_count:)
      end

      def to_h = { team: team&.to_s, psychic_count: }
      def to_json(state = nil) = to_h.to_json(state)
    end
  end
end
