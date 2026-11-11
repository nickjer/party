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

    saved_game, current_player, block_value =
      store.update(game.id, user_id: alice.user_id) do |game, acting_player|
        acting_player.score = 3
        game.begin_guessing(player: acting_player)
        :done
      end

    assert_equal game.id, saved_game.id
    assert_equal alice.id, current_player.id
    assert_equal :done, block_value
    assert_predicate store.find(game.id).status, :guessing?
    assert_equal 3, store.find(game.id).find_player(alice.id).score
  end

  test "#update raises when the user is not a player" do
    game = build_game(players: %w[Alice])
    store.save(game)

    assert_raises(ActiveRecord::RecordNotFound) do
      store.update(game.id, user_id: "nobody") { |_game, _acting_player| nil }
    end
  end

  test "#update writes nothing when the block raises" do
    game = build_game(players: %w[Alice Bob])
    store.save(game)
    alice = game.players.find { |player| player.name.to_s == "Alice" }

    assert_raises(GameStore::Rejected) do
      store.update(game.id, user_id: alice.user_id) do |game, acting_player|
        acting_player.score = 3
        game.begin_guessing(player: acting_player)
        raise GameStore::Rejected, "nope"
      end
    end

    reloaded = store.find(game.id)
    assert_predicate reloaded.status, :polling?
    assert_equal 0, reloaded.find_player(alice.id).score
  end

  test "#update loads fresh rows when the request already cached them" do
    game = build_game(players: %w[Alice Bob])
    store.save(game)
    alice = game.players.find { |player| player.name.to_s == "Alice" }

    seen = nil #: Integer?
    ActiveRecord::Base.cache do
      store.find(game.id) # primes the per-request query cache

      # Another request's commit: a raw statement, so this connection's
      # cache does not notice it.
      fresh = JSON.parse(alice.document_json).merge("score" => 42).to_json
      ActiveRecord::Base.connection.raw_connection
        .execute("UPDATE players SET document = ? WHERE id = ?",
          [fresh, alice.id])

      store.update(game.id, user_id: alice.user_id) do |_game, acting_player|
        seen = acting_player.score
      end
    end

    assert_equal 42, seen
    # The primed rows are still cached; read past them to see what was saved.
    stored = ActiveRecord::Base.uncached { store.find(game.id) }
    assert_equal 42, stored.find_player(alice.id).score
  end

  test "#join loads the game, yields it, and saves the new player" do
    game = build_game(players: %w[Alice])
    store.save(game)
    user = create(:user)

    saved_game, added_player = store.join(game.id) do |game|
      game.add_player(user_id: user.id, name: PlayerName.parse("Bob"))
    end

    assert_equal game.id, saved_game.id
    assert_equal "Bob", added_player.name.to_s
    assert_equal added_player.id, store.find(game.id).player_for!(user.id).id
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
