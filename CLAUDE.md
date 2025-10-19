# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Quick Start

```bash
# Setup
bin/rails db:setup              # Create database and load schema
bin/rails server                # Start server on http://localhost:3000

# Development workflow
bin/rails test                  # Run all tests
bin/steep check                 # Type check with RBS (run before committing)
bin/rubocop                     # Lint code
bin/brakeman                    # Security scan
npm run herb:lint app/views     # Lint HTML and ERB in views
```

## Project Overview

**Party** is a Rails 8 application - a composable, multi-game platform using document-oriented architecture where game-specific state is stored in JSON documents, allowing different game types to coexist without schema changes.

**Tech Stack**: Rails 8, Hotwire (Turbo & Stimulus), SQLite, RBS + Steep, Tailwind CSS, esbuild, Kamal

**Migrating from**: `../loaded_questions` (fully ported), `../burn_unit` (not yet ported). See `MIGRATION_REVIEW.md`.

**Coverage**: 100% for Loaded Questions (548/548), 93.77% overall (707/754). View in `coverage/index.html`.

## Core Architecture

### Database Schema

Document-oriented, game-agnostic design:

**Games**: `kind` (enum), `slug` (string), `document` (json - all game state)
**Players**: `game_id`, `user_id`, `name`, `document` (json - player state)
**Users**: Minimal tracking, no authentication

### Game Implementation Pattern

Games live under `/app/games/{game_name}/` with:
- Wrapper classes (game.rb, player.rb) - Encapsulate document JSON
- Controllers (games_controller.rb, players_controller.rb) - Namespaced
- Builder objects (create_new_game.rb, etc) - Construct entities
- Form objects (*_form.rb) - Validation without touching models
- Broadcast service objects (broadcast/*.rb) - Real-time updates
- Domain models (game/*.rb) - Value objects

### Shared Infrastructure (`/app/lib/`)

**NormalizedString**: Immutable value object for text (NFKC normalization, case-insensitive comparison)
**PlayerConnections**: Thread-safe singleton tracking online players with `increment/decrement/count`
**Errors**: Lightweight error container with `#add(attribute, message:)`, `#added?`, `#empty?`, `#[]`

### Real-time Communication

Player-based WebSocket architecture using Action Cable + Turbo Streams.

**PlayerChannel** - Players subscribe to their own GlobalID-based stream:
- Connection tracking via PlayerConnections singleton
- First/last connection optimization (multiple tabs don't duplicate broadcasts)
- Game-specific dispatching based on `game.kind`
- Custom `PlayerChannel.broadcast_to(players) { render template }` class method

**Two Broadcast Patterns**:

1. **Player-Specific** (initialize with `player_id:`): For individual actions (player joins, answers, connects/disconnects)
2. **Game-Wide** (initialize with `game_id:`): For phase transitions (round starts/ends, answers swapped), typically skip guesser

Each broadcaster:
- Initializes with `player_id:` or `game_id:`
- Loads game/player data
- Uses `PlayerChannel.broadcast_to` to iterate through online players
- Renders turbo_stream template for each recipient

**Usage**:
```ruby
# Player-specific
Broadcast::PlayerCreated.new(player_id: player.id).call

# Game-wide
Broadcast::RoundCreated.new(game_id: game.id).call
```

### Type System (RBS)

Type signatures in `/sig/`: `models.rbs`, `lib.rbs`, `loaded_questions.rbs`, `controllers.rbs`, `external.rbs`

**Always run `bin/steep check` before committing.**

## Loaded Questions Game

Guessing game with 4 phases:

1. **Polling**: Guesser creates game with question, players join and submit answers
2. **Guessing**: Answers shuffled, guesser matches answers to players via drag-and-drop
3. **Completed**: Shows correct/incorrect matches with score
4. **New Round**: Any non-guesser can start new round with new question, becomes new guesser

**Game document**: `{ question: String, status: String, guesses: Array }`
**Player document**: `{ active: Boolean, guesser: Boolean, answer: String }`

**Key Classes**:
- `LoadedQuestions::Game` - Wrapper with `question`, `status`, `guesses`, `guesser`, `players`, `swap_guesses`, etc
- `LoadedQuestions::Player` - Wrapper with `active?`, `guesser?`, `answer`, `answered?`, `online?`, etc
- `LoadedQuestions::Game::Status` - Value object with `polling?`, `guessing?`, `completed?`
- `LoadedQuestions::Game::Guesses` - Collection with `swap`, `score`, includes `Enumerable`
- Form objects: NewGameForm, NewPlayerForm, AnswerForm, GuessingRoundForm, CompletedRoundForm, NewRoundForm
- Builder objects: CreateNewGame, CreateNewRound, NewPlayer
- 8 broadcast service objects for real-time updates

## Development Patterns

### Working with Documents

```ruby
# Access
def document
  game.parsed_document  # Hash with symbol keys, memoized
end

# Update
document[:key] = value
game.document = document.to_json  # Resets cache
game.save!
```

### Form Objects

```ruby
class SomeForm
  attr_reader :field, :errors

  def initialize(field: nil)
    @field = NormalizedString.new(field)
    @errors = Errors.new  # NOT {} or []
  end

  def valid?
    errors.add(:field, message: "error") if invalid_condition
    errors.empty?
  end
end
```

**Usage**: `errors.add(attribute, message:)` - attribute is positional, message is keyword. Use `:base` for non-field errors.

### Builder Objects

Return saved, persisted objects. Use transactions for multiple objects. Return wrapped objects, not raw ActiveRecord.

### Creating Broadcast Service Objects

**Pattern 1: Player-Specific**
```ruby
class Broadcast::SomeEvent
  def initialize(player_id:)
    @affected_player = ::Player.find(player_id)
  end

  def call
    game = Game.from_id(affected_player.game_id)
    player = game.find_player(affected_player.id)

    PlayerChannel.broadcast_to(game.players) do |current_player|
      ApplicationController.render("game_name/players/some_event",
        formats: [:turbo_stream], locals: { current_player:, player: })
    end
  end
end
```

**Pattern 2: Game-Wide**
```ruby
class Broadcast::SomeGameEvent
  def initialize(game_id:)
    @game_id = game_id
  end

  def call
    game = Game.from_id(game_id)
    PlayerChannel.broadcast_to(game.players) do |current_player|
      next if current_player.guesser?  # Skip if needed
      ApplicationController.render("game_name/games/some_event",
        formats: [:turbo_stream], locals: { game:, current_player: })
    end
  end
end
```

### Adding a New Game

1. Add enum value to `Game::kind` in `app/models/game.rb`
2. Create namespace under `app/games/{game_name}/`
3. Implement wrapper classes, form objects, builders, controllers
4. Add namespaced routes
5. Create broadcast service objects
6. Add case branch in `PlayerChannel` for new game kind
7. Create RBS signatures in `sig/{game_name}.rbs`
8. Run `bin/steep check`

## Testing

### Running Tests

```bash
bin/rails test                                    # All tests
bin/rails test test/models/game_test.rb          # Specific file
bin/rails test test/system/loaded_questions/games_test.rb:285  # Specific test
```

### Test Conventions

**Descriptions**:
- Instance methods: `"#method returns ..."`
- Class methods: `".method returns ..."`
- System tests: `"descriptive flow name"`
- When description says "when X", assert X in test body

**Assertions**:
- Predicates: `assert_predicate obj, :method?` and `assert_not_predicate obj, :method?`
- Non-predicates: `assert_not` (not `refute`)
- DOM: `assert_dom "selector", text: "..."` and `assert_not_dom`
- System tests: Use `wait: 5` for async, `sleep 0.5` for DOM transitions

**Test helpers**:
- `sign_in(user)` - Signs in user for controller tests
- `reload(game:)` - Reloads game wrapper: `game = reload(game:)`

**Global setup** (`test/test_helper.rb`):
```ruby
setup do
  @player_connections = ::PlayerConnections.send(:new)
  ::PlayerConnections.stubs(:instance).returns(@player_connections)
end
```

### Testing Broadcast Service Objects

```ruby
require "turbo/broadcastable/test_helper"

class SomeEventTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  test "#call broadcasts to online players" do
    game = create(:lq_game, player_names: %w[Alice Bob])
    alice = game.players.find { |p| p.name.to_s == "Alice" }
    ::PlayerConnections.instance.increment(alice.id)

    assert_turbo_stream_broadcasts alice.to_model, count: 1 do
      SomeEvent.new(player_id: alice.id).call
    end
  end

  test "#call broadcasts correct action" do
    turbo_streams = capture_turbo_stream_broadcasts player.to_model do
      SomeEvent.new(player_id: player.id).call
    end

    assert_equal "replace", turbo_streams[0]["action"]
    assert_equal "player_#{player.id}", turbo_streams[0]["target"]
  end
end
```

### System Test Pattern

```ruby
test "multiple players" do
  visit new_loaded_questions_game_path
  fill_in "Player name", with: "Alice"
  click_on "Create New Game"
  game_slug = current_path.split("/").last

  using_session("bob") do
    visit new_loaded_questions_game_player_path(game_slug)
    fill_in "Name", with: "Bob"
    click_on "Create New Player"
  end

  using_session("default") do
    click_on "Begin Guessing"
  end
end
```

### Factories

**Key factory: `lq_game`**

```ruby
# Basic game
create(:lq_game)

# With player names
create(:lq_game, player_names: %w[Bob Charlie])

# With players and answers
create(:lq_game, players: [{ name: "Bob", answer: "Blue" }, { name: "Charlie", answer: "Red" }])

# Nested factories for specific states
create(:lq_matching_game)   # Guessing status
create(:lq_completed_game)  # Completed status
```

**Best practices**:
- Use `game.players.find(&:guesser?)` to find guesser
- Use `game.players.reject(&:guesser?)` to find non-guessers
- Use `game.player_for(user)` after reloading

## Coding Conventions

**Ruby**:
- Follow Rails Omakase (RuboCop enforced)
- Never use single-letter variable names
- Use keyword argument shorthand: `Person.new(name:, age:)` not `Person.new(name: name, age: age)`
- Use block shorthand: `game.players.find(&:guesser?)` not `game.players.find { |p| p.guesser? }`

**Views**:
- Use partials for reusable components
- Use Turbo Frames for independent sections
- Use confirmation modals for destructive actions
- **Turbo Frame Response Pattern**: Render same view for success/error, use status codes (`:ok` or `:unprocessable_content`)

**JavaScript**:
- Use Stimulus controllers (small, focused)
- Use data attributes for configuration
- Prefer stimulus-components for common patterns

## Deployment

```bash
bin/kamal deploy  # Deploy to production (config: config/deploy.yml)
```

## Related Applications

- `../loaded_questions` - Original Loaded Questions (PostgreSQL, UUIDs)
- `../burn_unit` - Original Burn Unit (PostgreSQL, UUIDs)

See `MIGRATION_REVIEW.md` for detailed comparison.
