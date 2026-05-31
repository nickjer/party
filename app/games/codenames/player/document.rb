# frozen_string_literal: true

module Codenames
  class Player
    # Immutable value object representing the parsed player document: the
    # player's team (nil until they pick one) and whether they are spymaster.
    class Document
      class << self
        def parse(hash)
          team = hash.fetch(:team)
          new(
            team: team ? Team.parse(team) : nil,
            spymaster: hash.fetch(:spymaster)
          )
        end
      end

      # @dynamic team, spymaster
      attr_reader :team, :spymaster

      def initialize(team:, spymaster:)
        @team = team
        @spymaster = spymaster
      end

      def with(team: @team, spymaster: @spymaster)
        self.class.new(team:, spymaster:)
      end

      def to_h = { team: team&.to_s, spymaster: }

      def to_json(state = nil) = to_h.to_json(state)
    end
  end
end
