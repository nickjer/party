# frozen_string_literal: true

module BurnUnit
  # Persistence boundary for Burn Unit players.
  class PlayerRepo
    class << self
      def generate_id = ::Player.generate_unique_id

      def hydrate(record)
        parsed_document = record.parsed_document #: Player::Document::json
        document = Player::Document.parse(parsed_document)
        Player.new(
          id: record.id,
          game_id: record.game_id,
          user_id: record.user_id,
          name: PlayerName.parse(record.name),
          document: document
        )
      end
    end
  end
end
