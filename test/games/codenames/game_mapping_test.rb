# frozen_string_literal: true

require "test_helper"

module Codenames
  class GameMappingTest < ActiveSupport::TestCase
    test "#kind is :codenames" do
      assert_equal :codenames, mapping.kind
    end

    test "#load_player rebuilds team and spymaster from a record" do
      game = create(:cn_playing_game)
      red_spy = game.players.find { |player| player.name.to_s == "RedSpy" }

      player = mapping.load_player(::Player.find(red_spy.id))

      assert_instance_of Codenames::Player, player
      assert_equal red_spy.id, player.id
      assert_equal Team.red, player.team
      assert_predicate player, :spymaster?
    end

    test "#load_game builds a Game aggregate from a record and players" do
      game = create(:cn_playing_game)
      record = ::Game.find(game.id)
      players = record.players.map { |player| mapping.load_player(player) }

      loaded = mapping.load_game(record, players)

      assert_instance_of Codenames::Game, loaded
      assert_equal game.id, loaded.id
      assert_equal players.map(&:id).sort, loaded.players.map(&:id).sort
    end

    private

    def mapping = GameMapping.new
  end
end
