# frozen_string_literal: true

module Wavelength
  class Game
    # Value object for the game status (the five round phases).
    class Status
      class << self
        private :new

        def completed = new(:completed)
        def guessing = new(:guessing)
        def left_right = new(:left_right)
        def reveal = new(:reveal)
        def setup = new(:setup)

        def parse(status)
          case status
          when "setup" then setup
          when "guessing" then guessing
          when "left_right" then left_right
          when "reveal" then reveal
          when "completed" then completed
          else raise(ArgumentError, "Unknown status: #{status}")
          end
        end
      end

      def initialize(status) = @status = status

      def ==(other) = status == other.status
      def as_json = status.to_s
      def completed? = status == :completed
      def eql?(other) = self == other
      def guessing? = status == :guessing
      def hash = status.hash
      def left_right? = status == :left_right
      def reveal? = status == :reveal
      def setup? = status == :setup
      def to_s = status.to_s

      protected

      # @dynamic status
      attr_reader :status
    end
  end
end
