# frozen_string_literal: true

module LoadedQuestions
  # Persistence boundary for Loaded Questions players. Wrappers are AR-ignorant;
  # this is the only place that touches ::Player.
  class PlayerRepo
    class << self
      def generate_id = ::Player.generate_unique_id
    end

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
