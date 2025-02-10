# frozen_string_literal: true

module LoadedQuestions
  class Game
    class MatchedAnswers
      class << self
        def parse(matched_answers, players:)
          player_map = players.index_by(&:id) #: Hash[Integer, Player]
          matches = matched_answers
            .map do |matched_answer|
              MatchedAnswer.new(
                player: player_map.fetch(matched_answer[:player_id]),
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
        match = matches.find { |match| match.player.id == player_id }
        if match.nil?
          raise ActiveRecord::RecordNotFound, "Couldn't find matched answer"
        end

        match
      end

      def size = matches.size

      private

      class MatchedAnswer
        # @dynamic player
        attr_reader :player

        # @dynamic answer
        attr_reader :answer

        def initialize(player:, answer:)
          @player = player
          @answer = answer
        end
      end

      # @dynamic matches
      attr_reader :matches
    end
  end
end
