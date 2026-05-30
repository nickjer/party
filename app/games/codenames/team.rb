# frozen_string_literal: true

module Codenames
  # Value object representing a team (red or blue). Shared by games and players.
  class Team
    class << self
      private :new

      def blue = new(:blue)

      def parse(team)
        case team
        when "red" then red
        when "blue" then blue
        else raise(ArgumentError, "Unknown team: #{team}")
        end
      end

      def red = new(:red)
    end

    def initialize(color) = @color = color

    def ==(other) = other.is_a?(Team) && color == other.color

    def as_json = color.to_s

    def blue? = color == :blue

    def eql?(other) = self == other

    def hash = color.hash

    def opponent = blue? ? Team.red : Team.blue

    def red? = color == :red

    def to_s = color.to_s

    protected

    # @dynamic color
    attr_reader :color
  end
end
