# frozen_string_literal: true

require "test_helper"

class GameStoreTest < ActiveSupport::TestCase
  test ".generate_game_id returns a unique String each call" do
    first = GameStore.generate_game_id
    assert_instance_of String, first
    assert_not_equal first, GameStore.generate_game_id
  end

  test ".generate_player_id returns a unique String each call" do
    first = GameStore.generate_player_id
    assert_instance_of String, first
    assert_not_equal first, GameStore.generate_player_id
  end

  test "#save persists a new game scoped to the mapping kind" do
    game = build_game(players: %w[Alice Bob])

    store.save(game)

    assert ::Game.loaded_questions.exists?(id: game.id)
  end

  test "#save persists every player on the game" do
    game = build_game(players: %w[Alice Bob])

    store.save(game)

    assert_equal game.players.map(&:id).sort,
      ::Player.where(game_id: game.id).pluck(:id).sort
  end

  test "#find round-trips a saved game into an aggregate" do
    game = build_game(players: %w[Alice Bob])
    store.save(game)

    loaded = store.find(game.id)

    assert_instance_of LoadedQuestions::Game, loaded
    assert_equal game.id, loaded.id
    assert_equal game.question, loaded.question
    assert_equal game.players.map(&:id).sort, loaded.players.map(&:id).sort
  end

  test "#find raises for an unknown id" do
    assert_raises(ActiveRecord::RecordNotFound) { store.find("missing") }
  end

  test "#save updates existing players without creating duplicates" do
    game = build_game(players: %w[Alice Bob])
    store.save(game)
    count_before = ::Player.where(game_id: game.id).count

    alice = game.players.find { |player| player.name.to_s == "Alice" }
    alice.score = 5
    store.save(game)

    assert_equal count_before, ::Player.where(game_id: game.id).count
    assert_equal 5, store.find(game.id).find_player(alice.id).score
  end

  test "#save persists document changes on an existing game" do
    game = build_game(players: %w[Alice Bob])
    store.save(game)

    game.begin_guessing
    store.save(game)

    assert_predicate store.find(game.id).status, :guessing?
  end

  private

  def store = GameStore.new(mapping: LoadedQuestions::GameMapping.new)

  def build_game(players: [])
    game = build(:lq_game)
    players.each do |name|
      game.add_player(user_id: create(:user).id, name: PlayerName.parse(name))
    end
    game
  end
end
