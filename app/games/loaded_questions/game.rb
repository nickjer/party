# frozen_string_literal: true

module LoadedQuestions
  class Game
    class << self
      def find(slug)
        relation = ::Game.strict_loading.loaded_questions.includes(:players)
        new(relation.find_by!(slug:))
      end
    end

    def initialize(game)
      @game = game
    end

    def hide_answers? = document.fetch(:hide_answers)

    def players = game.players.map { |player| Player.new(player, game: self) }

    def question = document.fetch(:question)

    def show_answers? = !hide_answers?

    def status = document.fetch(:status).to_sym

    private

    # @dynamic game
    attr_reader :game

    def document = game.parsed_document #: document
  end
end
