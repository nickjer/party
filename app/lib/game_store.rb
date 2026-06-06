# frozen_string_literal: true

# Shared persistence boundary for game aggregates. Owns the AR mechanics
# (query, transaction, player diffing); per-game construction and the game
# kind are supplied by an injected mapping.
class GameStore
  class << self
    def generate_game_id = ::Game.generate_unique_id

    def generate_player_id = ::Player.generate_unique_id
  end

  def initialize(mapping:)
    @mapping = mapping
  end

  def find(id)
    record = scope.find(id)
    players = record.players.map { |player| mapping.load_player(player) }
    mapping.load_game(record, players)
  end

  def save(game)
    ::Game.transaction do
      record = ::Game.find_or_initialize_by(id: game.id, kind: mapping.kind)
      record.document = game.document_json
      record.save! if record.changed?
      save_players(game)
    end
  end

  private

  # @dynamic mapping
  attr_reader :mapping

  def scope
    ::Game.strict_loading.where(kind: mapping.kind).includes(:players)
  end

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
