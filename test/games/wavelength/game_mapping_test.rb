# frozen_string_literal: true

require "test_helper"

module Wavelength
  class GameMappingTest < ActiveSupport::TestCase
    test "#kind is :wavelength" do
      assert_equal :wavelength, mapping.kind
    end

    test "#load_player rebuilds team and psychic_count from a record" do
      game = create(:wl_guessing_game)
      psychic = game.psychic

      player = mapping.load_player(::Player.find(psychic.id))

      assert_instance_of Wavelength::Player, player
      assert_equal psychic.id, player.id
      assert_equal psychic.team, player.team
      assert_equal 1, player.psychic_count
    end

    test "#load_game builds a Game aggregate from a record and players" do
      game = create(:wl_guessing_game)
      record = ::Game.find(game.id)
      players = record.players.map { |player| mapping.load_player(player) }

      loaded = mapping.load_game(record, players)

      assert_instance_of Wavelength::Game, loaded
      assert_equal game.id, loaded.id
      assert_equal players.map(&:id).sort, loaded.players.map(&:id).sort
    end

    private

    def mapping = GameMapping.new
  end
end
