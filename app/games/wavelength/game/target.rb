# frozen_string_literal: true

module Wavelength
  class Game
    # Immutable value object for the hidden bullseye: a 0-100 position plus all
    # scoring math (distance -> points, and which side a dial fell on).
    class Target
      BULLSEYE = 3   # |dial - position| <= 3 -> 4 points
      INNER    = 5   #                     <= 5 -> 3 points
      OUTER    = 8   #                     <= 8 -> 2 points

      class << self
        def generate
          position = rand(0..100) #: Integer
          new(position:)
        end
      end

      # @dynamic position
      attr_reader :position

      def initialize(position:) = @position = position

      def ==(other) = other.is_a?(Target) && position == other.position
      def eql?(other) = self == other
      def hash = position.hash

      def score_for(dial)
        distance = (position - dial).abs
        return 4 if distance <= BULLSEYE
        return 3 if distance <= INNER
        return 2 if distance <= OUTER

        0
      end

      # Which side the true target sits on, relative to the locked dial.
      def side_of(dial)
        return :left if position < dial
        return :right if position > dial

        :exact
      end
    end
  end
end
