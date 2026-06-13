# frozen_string_literal: true

module Wavelength
  class Game
    # Immutable value object for a drawn spectrum card: its two opposing labels.
    class Spectrum
      class << self
        def parse(hash)
          new(left: hash.fetch(:left), right: hash.fetch(:right))
        end
      end

      # @dynamic left, right
      attr_reader :left, :right

      def initialize(left:, right:)
        @left = left
        @right = right
      end

      def ==(other)
        other.is_a?(Spectrum) && left == other.left && right == other.right
      end

      def eql?(other) = self == other
      def hash = [left, right].hash
      def to_h = { left:, right: }
    end
  end
end
