# frozen_string_literal: true

module Codenames
  class Game
    # Immutable value object for the spymaster's clue: a word plus a number
    # from 0 to 9, or nil for unlimited.
    class Clue
      class << self
        def parse(hash)
          new(
            word: ::NormalizedString.new(hash.fetch(:word)),
            number: hash.fetch(:number)
          )
        end
      end

      # @dynamic word, number
      attr_reader :word, :number

      def initialize(word:, number:)
        if !number.nil? && !number.between?(0, 9)
          raise ArgumentError, "Number must be between 0 and 9: #{number}"
        end

        @word = word
        @number = number
      end

      def ==(other)
        other.is_a?(Clue) && word == other.word && number == other.number
      end

      def eql?(other) = self == other

      # Official rules: operatives get number + 1 guesses; 0 and unlimited
      # clues have no cap.
      def guess_limit
        count = number
        return nil if count.nil? || count.zero?

        count + 1
      end

      def hash = [word, number].hash

      def number_display = unlimited? ? "∞" : number.to_s

      def to_h = { word: word.to_s, number: }

      def unlimited? = number.nil?
    end
  end
end
