# frozen_string_literal: true

module LoadedQuestions
  class Game
    class Status
      class << self
        private :new

        def polling = new(:polling)

        def matching = new(:matching)

        def completed = new(:completed)

        def parse(status)
          case status
          when "polling" then polling
          when "matching" then matching
          when "completed" then completed
          else raise(ArgumentError, "Unknown status: #{status}")
          end
        end
      end

      def initialize(status) = @status = status

      def polling? = status == :polling

      def matching? = status == :matching

      def completed? = status == :completed

      def ==(other) = status == other.status

      def eql?(other) = self == other

      def hash = status.hash

      protected

      # @dynamic status
      attr_reader :status
    end
  end
end
