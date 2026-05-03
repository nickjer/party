# frozen_string_literal: true

module LoadedQuestions
  # Persistence boundary for Loaded Questions games. The wrapper aggregate
  # is AR-ignorant; this repo is the only place that knows about ::Game and
  # ::Player. Hydration order matters: parse the document, hydrate players,
  # then resolve guesses against those players.
  class GameRepo
    class << self
      def generate_id = ::Game.generate_unique_id

      def find(id)
        record = scope.find(id)
        parsed_document = record.parsed_document #: Game::Document::json
        document = Game::Document.parse(parsed_document)
        players = record.players.map { |player| PlayerRepo.hydrate(player) }
        guesses = Game::Guesses.parse(document.guesses_data, players:)
        Game.new(id: record.id, document:, players:, guesses:)
      end

      def save(game)
        ::Game.transaction do
          record = ::Game.find_or_initialize_by(id: game.id) do |new_record|
            new_record.kind = :loaded_questions
          end
          record.document = game.document_json
          record.save! if record.changed?
          save_players(game)
        end
      end

      private

      def scope = ::Game.strict_loading.loaded_questions.includes(:players)

      def save_players(game)
        game.players.each do |player|
          record = ::Player.find_or_initialize_by(id: player.id) do |new_record|
            new_record.game_id = player.game_id
            new_record.user_id = player.user_id
          end
          record.name = player.name.to_s
          record.document = player.document_json
          record.save! if record.changed?
        end
      end
    end
  end
end
