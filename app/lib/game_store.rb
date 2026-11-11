# frozen_string_literal: true

# Shared persistence boundary for game aggregates. Owns the AR mechanics
# (query, transaction, player diffing); per-game construction and the game
# kind are supplied by an injected mapping.
#
# Requests that change an existing game go through #update or #join, which
# load and save inside one immediate transaction so nothing can move between
# the read and the write. #save is for aggregates built in memory (new games).
class GameStore
  # Raised by an aggregate when a request breaks a rule of the game: wrong
  # phase, wrong player, stale board. ApplicationController renders it as 403.
  class Rejected < StandardError; end

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

  # Loads the game under the transaction, resolves the acting player, yields
  # both for mutation, and saves. Returns the game, the player, and the
  # block's value (useful for a form validated against the fresh game).
  #
  # SQLite transactions are immediate under Rails, so the write lock is held
  # from the load onward and the diff in #save_players is exact. The whole
  # body runs uncached: Rails' per-request query cache survives BEGIN, so a
  # request that read this game earlier would otherwise get those rows back
  # and write them over another request's commit.
  def update(id, user_id:)
    # Captured outside the block: Steep cannot type a tuple built inside it.
    current_player = nil #: untyped
    block_value = nil #: untyped
    saved_game = ::Game.uncached do
      ::Game.transaction do
        game = find(id)
        current_player = game.player_for!(user_id)
        block_value = yield(game, current_player)
        save(game)
        game
      end
    end
    [saved_game, current_player, block_value]
  end

  # Like #update, for a request whose user is not a player yet (joining).
  def join(id)
    block_value = nil #: untyped
    saved_game = ::Game.uncached do
      ::Game.transaction do
        game = find(id)
        block_value = yield(game)
        save(game)
        game
      end
    end
    [saved_game, block_value]
  end

  # Persists an aggregate built in memory. Not for a game loaded by #find in
  # the same request: the load and the save would not share a transaction.
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
