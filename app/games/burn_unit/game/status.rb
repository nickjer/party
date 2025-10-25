# frozen_string_literal: true

module BurnUnit
  class Game
    # Value object representing game status (polling or completed).
    class Status
      class << self
        private :new

        def completed = new(:completed)

        def parse(status)
          case status
          when "polling" then polling
          when "completed" then completed
          else raise(ArgumentError, "Unknown status: #{status}")
          end
        end

        def polling = new(:polling)
      end

      def initialize(status) = @status = status

      def ==(other) = status == other.status

      def as_json = status.to_s

      def completed? = status == :completed

      def eql?(other) = self == other

      def hash = status.hash

      def polling? = status == :polling

      def to_s = status.to_s

      protected

      # @dynamic status
      attr_reader :status
    end
  end
end
