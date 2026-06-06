# frozen_string_literal: true

module BurnUnit
  # Supplies Burn Unit construction to the shared GameStore.
  class GameMapping
    def kind = :burn_unit

    def load_game(record, players)
      parsed = record.parsed_document #: Game::Document::json
      Game.new(id: record.id, document: Game::Document.parse(parsed), players:)
    end

    def load_player(record)
      parsed = record.parsed_document #: Player::Document::json
      Player.new(
        id: record.id,
        game_id: record.game_id,
        user_id: record.user_id,
        name: PlayerName.new(record.name),
        document: Player::Document.parse(parsed)
      )
    end
  end
end
