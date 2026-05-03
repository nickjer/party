# frozen_string_literal: true

module BurnUnit
  # Persistence boundary for Burn Unit games. Wrappers are AR-ignorant;
  # this is the only place that touches ::Game and ::Player.
  class GameRepo
    class << self
      def generate_id = ::Game.generate_unique_id
    end

    def initialize
      @player_repo = PlayerRepo.new
    end

    def find(id)
      record = scope.find(id)
      parsed_document = record.parsed_document #: Game::Document::json
      document = Game::Document.parse(parsed_document)
      players = record.players.map { |player| player_repo.hydrate(player) }
      Game.new(id: record.id, document:, players:)
    end

    def save(game)
      ::Game.transaction do
        record = ::Game.find_or_initialize_by(
          id: game.id, kind: :burn_unit
        )
        record.document = game.document_json
        record.save! if record.changed?
        save_players(game)
      end
    end

    private

    # @dynamic player_repo
    attr_reader :player_repo

    def scope = ::Game.strict_loading.burn_unit.includes(:players)

    def save_players(game)
      existing = ::Player
        .where(game_id: game.id, id: game.players.map(&:id))
        .index_by(&:id)
      game.players.each do |player|
        record = existing[player.id] || ::Player.new(
          id: player.id, game_id: player.game_id, user_id: player.user_id
        )
        record.name = player.name.to_s
        record.document = player.document_json
        record.save! if record.changed?
      end
    end
  end
end
