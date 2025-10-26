# frozen_string_literal: true

module BurnUnit
  class Game
    # Value object representing a candidate with their voters and winner status
    class Candidate
      class << self
        def from(playing_players)
          voters_by_candidate = {} #: Hash[String, Array[Player]]
          playing_players.each do |player|
            vote = player.vote
            (voters_by_candidate[vote] ||= []) << player if vote
          end

          vote_count_map = voters_by_candidate.transform_values(&:size)
          max_votes = vote_count_map.values.max || 0

          candidates = playing_players.map do |player|
            voters = voters_by_candidate[player.id] || []
            vote_count = vote_count_map[player.id]
            winner = vote_count == max_votes && max_votes.positive?
            new(player:, voters:, winner:)
          end

          candidates.sort_by do |candidate|
            [-candidate.vote_count, candidate.name]
          end
        end
      end

      # @dynamic player, voters
      attr_reader :player, :voters

      def initialize(player:, voters:, winner:)
        @player = player
        @voters = voters.sort
        @winner = winner
      end

      def id = player.id

      def name = player.name

      def vote_count = voters.size

      def winner? = @winner
    end
  end
end
