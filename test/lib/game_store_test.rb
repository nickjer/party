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

    game.begin_guessing(player: game.guesser)
    store.save(game)

    assert_predicate store.find(game.id).status, :guessing?
  end

  test "#update loads the game, yields the acting player, and saves" do
    game = build_game(players: %w[Alice Bob])
    store.save(game)
    alice = game.players.find { |player| player.name.to_s == "Alice" }

    loaded, player, value =
      store.update(game.id, user_id: alice.user_id) do |fresh, acting|
        acting.score = 3
        fresh.begin_guessing(player: acting)
        :done
      end

    assert_equal game.id, loaded.id
    assert_equal alice.id, player.id
    assert_equal :done, value
    assert_predicate store.find(game.id).status, :guessing?
    assert_equal 3, store.find(game.id).find_player(alice.id).score
  end

  test "#update raises when the user is not a player" do
    game = build_game(players: %w[Alice])
    store.save(game)

    assert_raises(ActiveRecord::RecordNotFound) do
      store.update(game.id, user_id: "nobody") { |_fresh, _acting| nil }
    end
  end

  test "#update writes nothing when the block raises" do
    game = build_game(players: %w[Alice Bob])
    store.save(game)
    alice = game.players.find { |player| player.name.to_s == "Alice" }

    assert_raises(GameStore::Rejected) do
      store.update(game.id, user_id: alice.user_id) do |fresh, acting|
        acting.score = 3
        fresh.begin_guessing(player: acting)
        raise GameStore::Rejected, "nope"
      end
    end

    reloaded = store.find(game.id)
    assert_predicate reloaded.status, :polling?
    assert_equal 0, reloaded.find_player(alice.id).score
  end

  test "#join loads the game, yields it, and saves the new player" do
    game = build_game(players: %w[Alice])
    store.save(game)
    user = create(:user)

    loaded, added = store.join(game.id) do |fresh|
      fresh.add_player(user_id: user.id, name: PlayerName.parse("Bob"))
    end

    assert_equal game.id, loaded.id
    assert_equal "Bob", added.name.to_s
    assert_equal added.id, store.find(game.id).player_for!(user.id).id
  end

  private

  def store = GameStore.new(mapping: LoadedQuestions::GameMapping.new)

  # The first player listed is the guesser.
  def build_game(players: [])
    game = build(:lq_game)
    players.each_with_index do |name, index|
      game.add_player(user_id: create(:user).id, name: PlayerName.parse(name),
        guesser: index.zero?)
    end
    game
  end
end
