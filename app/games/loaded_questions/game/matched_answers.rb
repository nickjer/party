# frozen_string_literal: true

module LoadedQuestions
  class Game
    class MatchedAnswers
      class << self
        def parse(matched_answers)
          matches = matched_answers
            .map do |matched_answer|
              MatchedAnswer.new(
                player_id: matched_answer[:player_id],
                answer: matched_answer[:answer]
              )
            end
          new(matches:)
        end
      end

      include Enumerable

      def initialize(matches:) = @matches = matches

      def each(&block)
        matches.each(&block)
        self
      end

      def find(player_id)
        match = matches.find { |match| match.player_id == player_id }
        if match.nil?
          raise ActiveRecord::RecordNotFound, "Couldn't find matched answer"
        end

        match
      end

      private

      class MatchedAnswer
        # @dynamic player_id
        attr_reader :player_id

        # @dynamic answer
        attr_reader :answer

        def initialize(player_id:, answer:)
          @player_id = player_id
          @answer = answer
        end
      end

      # @dynamic matches
      attr_reader :matches
    end
  end
end
