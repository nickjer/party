# frozen_string_literal: true

module LoadedQuestions
  class Game
    class Status
      class << self
        private :new

        def polling = new(:polling)

        def guessing = new(:guessing)

        def completed = new(:completed)

        def parse(status)
          case status
          when "polling" then polling
          when "guessing" then guessing
          when "completed" then completed
          else raise(ArgumentError, "Unknown status: #{status}")
          end
        end
      end

      def initialize(status) = @status = status

      def polling? = status == :polling

      def guessing? = status == :guessing

      def completed? = status == :completed

      def to_s = status.to_s

      def ==(other) = status == other.status

      def eql?(other) = self == other

      def hash = status.hash

      protected

      # @dynamic status
      attr_reader :status
    end
  end
end
