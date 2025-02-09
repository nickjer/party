# frozen_string_literal: true

module LoadedQuestions
  class Game
    class << self
      def find(slug)
        relation = ::Game.strict_loading.loaded_questions
          .includes(players: :user)
        new(relation.find_by!(slug:))
      end
    end

    def initialize(game)
      @game = game
    end

    def broadcast_reload_game = game.broadcast_reload_game

    def broadcast_reload_players = game.broadcast_reload_players

    def id = game.id

    def player_for!(user)
      player_for(user) ||
        raise(ActiveRecord::RecordNotFound, "Couldn't find Player")
    end

    def player_for(user) = players.find { |player| player.user == user }

    def players
      game.players.map { |player| Player.new(player, game: self) }.sort
    end

    def question = document.fetch(:question)

    def slug = game.slug

    def status = Status.parse(document.fetch(:status))

    def to_gid_param = game.to_gid_param

    def update_status(status)
      document[:status] = status.to_s
      game.document = document.to_json
      game.save!
    end

    private

    # @dynamic game
    attr_reader :game

    def document = game.parsed_document #: document
  end
end
