# frozen_string_literal: true

module Wavelength
  class Game
    # Immutable value object for the hidden bullseye: a 0-100 position plus all
    # scoring math (distance -> points, and which side a dial fell on).
    class Target
      # Half-unit thresholds give five equal wedges (each 5 integers wide), a
      # full 25% scoring band, and no boundary ties (dial distances are whole).
      BULLSEYE = 2.5  # |dial - position| <= 2.5 -> 4 points
      INNER    = 7.5  #                   <= 7.5 -> 3 points
      OUTER    = 12.5 #                   <= 12.5 -> 2 points

      # One scoring wedge mapped onto the 0..100 track for rendering the
      # revealed target. `points` is what a dial landing inside it scores.
      class Band
        # @dynamic points, from, to
        attr_reader :points, :from, :to

        def initialize(points:, from:, to:)
          @points = points
          @from = from
          @to = to
        end

        def width = to - from
      end

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

      # The five scoring wedges (2-3-4-3-2) clamped onto the 0..100 track,
      # ordered left to right for rendering the revealed target.
      def bands
        @bands ||= [
          band(low: -OUTER, high: -INNER, points: 2),
          band(low: -INNER, high: -BULLSEYE, points: 3),
          band(low: -BULLSEYE, high: BULLSEYE, points: 4),
          band(low: BULLSEYE, high: INNER, points: 3),
          band(low: INNER, high: OUTER, points: 2)
        ]
      end

      private

      def band(low:, high:, points:)
        Band.new(points:, from: (position + low).clamp(0.0, 100.0),
          to: (position + high).clamp(0.0, 100.0))
      end
    end
  end
end
