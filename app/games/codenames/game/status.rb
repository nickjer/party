# frozen_string_literal: true

module Codenames
  class Game
    # Value object representing game status (setup, playing, or completed).
    class Status
      class << self
        private :new

        def completed = new(:completed)

        def parse(status)
          case status
          when "setup" then setup
          when "playing" then playing
          when "completed" then completed
          else raise(ArgumentError, "Unknown status: #{status}")
          end
        end

        def playing = new(:playing)

        def setup = new(:setup)
      end

      def initialize(status) = @status = status

      def ==(other) = status == other.status

      def as_json = status.to_s

      def completed? = status == :completed

      def eql?(other) = self == other

      def hash = status.hash

      def playing? = status == :playing

      def setup? = status == :setup

      def to_s = status.to_s

      protected

      # @dynamic status
      attr_reader :status
    end
  end
end
