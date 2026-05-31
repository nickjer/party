# frozen_string_literal: true

module Codenames
  class Game
    # Value object for a card's secret identity (red/blue agent, bystander,
    # or assassin). Only spymasters see identities until a card is revealed.
    class Identity
      class << self
        private :new

        def agent(team) = team.red? ? red : blue

        def assassin = new(:assassin)

        def blue = new(:blue)

        def bystander = new(:bystander)

        def parse(identity)
          case identity
          when "red" then red
          when "blue" then blue
          when "bystander" then bystander
          when "assassin" then assassin
          else raise(ArgumentError, "Unknown identity: #{identity}")
          end
        end

        def red = new(:red)
      end

      def initialize(kind) = @kind = kind

      def ==(other) = other.is_a?(Identity) && kind == other.kind

      def agent? = %i[red blue].include?(kind)

      def as_json = kind.to_s

      def assassin? = kind == :assassin

      def bystander? = kind == :bystander

      def eql?(other) = self == other

      def hash = kind.hash

      def team
        case kind
        when :red then Team.red
        when :blue then Team.blue
        end
      end

      def to_s = kind.to_s

      protected

      # @dynamic kind
      attr_reader :kind
    end
  end
end
