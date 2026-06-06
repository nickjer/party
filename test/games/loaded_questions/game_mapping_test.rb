# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class GameMappingTest < ActiveSupport::TestCase
    test "#kind is :loaded_questions" do
      assert_equal :loaded_questions, mapping.kind
    end

    test "#load_player builds a Player aggregate from a record" do
      game = create(:lq_polling_game, player_names: %w[Alice])
      alice = game.players.find { |player| player.name.to_s == "Alice" }

      player = mapping.load_player(::Player.find(alice.id))

      assert_instance_of LoadedQuestions::Player, player
      assert_equal alice.id, player.id
      assert_equal "Alice", player.name.to_s
    end

    test "#load_game builds a Game aggregate from a record and players" do
      game = create(:lq_polling_game, player_names: %w[Alice Bob])
      record = ::Game.find(game.id)
      players = record.players.map { |player| mapping.load_player(player) }

      loaded = mapping.load_game(record, players)

      assert_instance_of LoadedQuestions::Game, loaded
      assert_equal game.id, loaded.id
      assert_equal players.map(&:id).sort, loaded.players.map(&:id).sort
    end

    private

    def mapping = GameMapping.new
  end
end
