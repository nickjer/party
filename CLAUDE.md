# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Start

```bash
# Setup
bin/rails db:setup              # Create database and load schema
bin/rails server                # Start server on http://localhost:3000

# Development workflow
bin/rails test                  # Run all tests
bin/rails test test/system      # Run system tests
bin/steep check                 # Type check with RBS
bin/brakeman                    # Security scan
bin/rubocop                     # Lint code
bin/erb_lint --lint-all         # Lint ERB templates
```

## Project Overview

**Party** is a Rails 8 application - a composable, multi-game platform designed to host multiple party games under a single application. It uses a document-oriented architecture where game-specific state is stored in JSON documents, allowing different game types to coexist without schema changes.

### Migration Status

The app is being migrated from two standalone applications:
- `../loaded_questions` - A guessing/matching game (partially ported)
- `../burn_unit` - A voting game (not yet ported)

See `MIGRATION_REVIEW.md` for a comprehensive analysis of the migration status.

### Tech Stack

- **Rails 8** with Hotwire (Turbo & Stimulus)
- **SQLite** for development/production
- **RBS + Steep** for type checking
- **Tailwind CSS** for styling
- **esbuild** for JavaScript bundling
- **Kamal** for deployment

## Development Commands

### Running the Application
```bash
bin/rails server        # Start Rails server
bin/dev                 # Start Rails + asset watchers (if configured)
```

### Database
```bash
bin/rails db:create     # Create databases
bin/rails db:migrate    # Run migrations
bin/rails db:reset      # Drop, create, migrate, and seed
bin/rails db:seed       # Load seed data
bin/rails db:setup      # Create, migrate, and seed (initial setup)
```

### Testing
```bash
bin/rails test                                      # Run all tests
bin/rails test test/models/game_test.rb            # Run specific test file
bin/rails test test/system                         # Run system tests
bin/rails test test/system/loaded_questions/games_test.rb  # Run specific system test
```

### Type Checking (RBS + Steep)
```bash
bin/steep check         # Type check the entire application
bin/steep watch         # Watch mode for continuous type checking
```

Type signatures are in `/sig/` directory. The project uses RBS extensively for type safety.
**Always run `bin/steep check` before committing changes.**

### Linting and Security
```bash
bin/rubocop             # Run RuboCop linter (Rails Omakase config)
bin/rubocop -a          # Auto-correct offenses where possible
bin/brakeman            # Run security vulnerability scanner
```

### Assets
```bash
npm run build           # Build JavaScript with esbuild
npm run build:css       # Build Tailwind CSS
bin/rails assets:precompile  # Precompile all assets for production
```

**JavaScript source**: `app/javascript/`
**Output**: `app/assets/builds/`

## Architecture

### Core Schema Design

The app uses a **document-oriented, game-agnostic database schema**:

**Games table**:
- `kind` (integer enum) - Identifies game type (e.g., `loaded_questions: 0`)
- `slug` (string) - URL-friendly game identifier
- `document` (json) - All game-specific state stored here

**Players table**:
- `game_id`, `user_id`, `name` - Basic relational data
- `document` (json) - Player-specific state for the game

**Users table**:
- Minimal user tracking (`last_seen_at`)
- No authentication - just session persistence

All game-specific logic lives in JSON documents, making the schema extremely flexible.

### Game Implementation Pattern

Games are implemented as namespaced modules under `/app/games/{game_name}/`:

```
/app/games/loaded_questions/
  ├── game.rb                 # Wrapper around ::Game model
  ├── player.rb               # Wrapper around ::Player model
  ├── games_controller.rb     # Game-specific controller
  ├── players_controller.rb   # Player management
  ├── new_game.rb             # Builder object
  ├── new_player.rb           # Builder object
  ├── *_form.rb               # Form objects for validation
  ├── broadcast/              # Real-time broadcast service objects
  │   ├── player_connected.rb
  │   ├── player_created.rb
  │   ├── player_disconnected.rb
  │   └── answer_updated.rb
  └── game/
      ├── status.rb           # Value object for game state
      └── guesses.rb          # Domain model for guess collection
```

**Key principles**:
1. Wrapper classes encapsulate document JSON parsing
2. Form objects handle validation without touching models
3. Builder objects construct complex entities
4. Broadcast service objects handle real-time updates
5. Controllers are namespaced (e.g., `LoadedQuestions::GamesController`)
6. Routes are namespaced (e.g., `namespace :loaded_questions`)

### Shared Infrastructure

**Location**: `/app/lib/`

**NormalizedString** (`normalized_string.rb`):
- Immutable value object for text normalization
- NFKC Unicode normalization + squish + control char removal
- Case-insensitive comparison via `sortable_value`
- Used for player names, answers, and all user text input

**PlayerConnections** (`player_connections.rb`):
- Singleton tracking online player connections
- Thread-safe using `Concurrent::Map` via `ScoreMap`
- Powers the "online?" indicator for players

**ScoreMap** (`score_map.rb`):
- Generic thread-safe counter/accumulator
- Uses `Concurrent::Map` for safe concurrent access
- Reusable for connection tracking, scoring, tallies, etc.

**Errors** (`errors.rb`):
- Lightweight errors container similar to ActiveModel::Errors
- Stores multiple error messages per attribute using `Hash[Symbol, Set[Error]]`
- Methods: `#add(attribute, message:)`, `#added?(attribute, message:)`, `#empty?`, `#[]`
- `#[]` returns an Array of `Error` objects for the given attribute
- Nested `Errors::Error` class with proper humanization (`:email_address` → "Email address")
- Used in all form objects for validation error tracking
- Integrates with `BootstrapFormBuilder` for inline error display

### Real-time Communication

The app uses a **player-based WebSocket architecture** with Action Cable and Turbo Streams. Each player subscribes to their own channel, and broadcast service objects handle real-time updates.

#### PlayerChannel (`app/channels/player_channel.rb`)

Players subscribe to their own channel using a GlobalID-based stream:

```ruby
class PlayerChannel < ApplicationCable::Channel
  def subscribed
    @player = GlobalID.find(stream_name)
    return reject if player.user != current_user  # Verify ownership

    stream_from stream_name

    # Track connection and trigger game-specific broadcaster
    count = ::PlayerConnections.instance.increment(player.id)
    return if count > 1  # Only broadcast on first connection

    # Dispatch to game-specific broadcaster
    broadcaster = case game_kind
    when :loaded_questions
      LoadedQuestions::Broadcast::PlayerConnected.new(player_id: player.id)
    end
    broadcaster.call
  end

  def unsubscribed
    count = ::PlayerConnections.instance.decrement(player.id)
    return if count.positive?  # Only broadcast on last disconnect

    broadcaster = case game_kind
    when :loaded_questions
      LoadedQuestions::Broadcast::PlayerDisconnected.new(player_id: player.id)
    end
    broadcaster.call
  end
end
```

**Key features**:
- Player-level subscription with user authentication
- Connection tracking via `PlayerConnections` singleton
- First/last connection optimization (multiple tabs don't trigger duplicate broadcasts)
- Game-specific dispatching based on `game.kind`
- Custom `PlayerChannel.broadcast_to(players) { render template }` class method

#### Connection Authentication (`app/channels/application_cable/connection.rb`)

```ruby
class Connection < ActionCable::Connection::Base
  identified_by :current_user

  def connect
    self.current_user = find_verified_user
  end

  private

  def find_verified_user
    if (verified_user = User.find_by(id: cookies.encrypted[:current_user_id]))
      verified_user
    else
      reject_unauthorized_connection
    end
  end
end
```

WebSocket connections are authenticated using encrypted session cookies, making `current_user` available in all channels.

#### Broadcast Service Objects

Broadcast services follow a consistent pattern:

```ruby
class Broadcast::SomeEvent
  def initialize(player_id:)
    @affected_player = ::Player.find(player_id)
  end

  def call
    game = Game.from_id(affected_player.game_id)

    PlayerChannel.broadcast_to(game.players) do |current_player|
      ApplicationController.render(
        "loaded_questions/players/some_event",
        formats: [:turbo_stream],
        locals: { current_player:, player: }
      )
    end
  end
end
```

**Available broadcasters** (`app/games/loaded_questions/broadcast/`):

- **PlayerConnected**: Updates player online status when they connect
- **PlayerCreated**: Adds new player to all players' lists
- **PlayerDisconnected**: Updates player offline status when they disconnect
- **AnswerUpdated**: Shows checkmark when player submits an answer

Each broadcaster:
1. Initializes with `player_id`
2. Loads game and player state
3. Uses `PlayerChannel.broadcast_to` to iterate through all players
4. Renders a turbo_stream template for each online player
5. Broadcasts individual updates via `Turbo::StreamsChannel`

**Usage in controllers**:
```ruby
# After creating a player
Broadcast::PlayerCreated.new(player_id: player.id).call

# After player submits an answer
Broadcast::AnswerUpdated.new(player_id: current_player.id).call
```

#### Game-Level Broadcasting

For major game state changes (phase transitions), use model-level broadcast methods:

```ruby
game.broadcast_reload_game      # Reloads entire game state for all players
game.broadcast_reload_players   # Updates player list for all players
```

These are simpler broadcasts that reload entire page sections instead of granular updates.

**Usage in controllers**:
```ruby
# When transitioning to guessing phase
game.update_status(Game::Status.guessing)
game.broadcast_reload_game

# When swapping guesses
game.swap_guesses(player_id1:, player_id2:)
game.broadcast_reload_game
```

#### Two Broadcasting Patterns

| Pattern | When to Use | Example | Location |
|---------|------------|---------|----------|
| **Broadcast Service Objects** | Granular entity updates | Player joins, answers submitted | `app/games/{game}/broadcast/*.rb` |
| **Model Broadcast Methods** | Full state reloads | Phase transitions, guess swaps | `game.broadcast_reload_game` |

Both patterns ensure all online players see updates in real-time via Turbo Streams.

### Type System (RBS)

Type signatures in `/sig/`:
- `models.rbs` - Core ActiveRecord models
- `lib.rbs` - Shared utilities (NormalizedString, PlayerConnections, ScoreMap)
- `loaded_questions.rbs` - Complete game module types
- `controllers.rbs` - Controller instance variables
- `external.rbs` - Third-party library types

**Key patterns**:
- Generic types: `ScoreMap[K]`
- Structural typing: `_ToS` for anything with `to_s`
- Hash types with symbol keys: `{ question: String, status: String }`
- ActiveRecord relation types are fully specified

### JavaScript/Stimulus Controllers

Controllers in `app/javascript/controllers/`:

**dialog_controller** (from stimulus-components):
- Handles modal/dialog interactions
- Used for confirmation modals (Begin Guessing, Complete Matching)
- Provides `open()` and `close()` actions
- Wraps native `<dialog>` element

**swap_controller.js**:
- Uses SortableJS with Swap plugin
- Enables drag-and-drop reordering of answers
- Sends swap events via fetch to backend endpoint
- Connected to `GamesController#swap_guesses` for Loaded Questions

**hello_controller.js**:
- Example Stimulus controller

When adding new controllers:
1. Create in `app/javascript/controllers/`
2. Use Stimulus naming conventions
3. Import automatically via `controllers/index.js`

## Loaded Questions Game

### Game Flow

**Loaded Questions** is a guessing game where one player (the guesser) tries to match answers to the players who wrote them.

**Phase 1: Polling (Status: "polling")**
1. Guesser creates a game with a question
2. Other players join the game
3. Players submit text answers to the question
4. Guesser waits until enough answers are submitted
5. Guesser clicks "Begin Guessing" (with confirmation modal)

**Phase 2: Guessing (Status: "guessing")**
1. Answers are shuffled and displayed to all players
2. Guesser sees answers matched to players in random order
3. Guesser can swap answers to match them to the correct players (drag-and-drop)
4. Guesser clicks "Complete Matching" (with confirmation modal)

**Phase 3: Completed (Status: "completed")** - Not Yet Implemented
1. Show correct matches vs guesser's guesses
2. Calculate and display score
3. Option to start a new round with a different guesser

### Document Structure

**Game document**:
```ruby
{
  question: "What is your favorite color?",
  status: "polling",  # or "guessing", "completed"
  guesses: [
    { player_id: 2, answer: "Blue", guessed_player_id: 2 },
    { player_id: 3, answer: "Red", guessed_player_id: 3 }
  ]
}
```

**Player document**:
```ruby
{
  guesser: true,  # or false
  answer: "Blue"  # or nil if not yet submitted
}
```

### Implementation Status

**✅ Working**:
- Game creation with initial question
- Player joining with real-time updates
- Answer submission (polling phase)
- Transition to guessing phase (answers shuffled) with confirmation modal
- Display of shuffled answers
- Real-time player online/offline indicators via WebSocket
- Answer swapping via drag-and-drop (guesser can reorder matches)
- Real-time broadcast of player actions (connect, disconnect, answer submit)
- Confirmation modals for phase transitions (Begin Guessing, Complete Matching)
- Comprehensive system tests for game flow and modal interactions

**❌ Not Yet Implemented**:
- Round completion and results display
- Score calculation
- Multiple rounds per game
- Score tracking across rounds
- Starting new turns/rotating guesser
- Player removal
- Hide answers toggle

### Key Classes

**LoadedQuestions::Game** (`app/games/loaded_questions/game.rb`)
- Wrapper around `::Game` model
- Provides access to game document fields
- Methods: `question`, `status`, `guesses`, etc.

**LoadedQuestions::Player** (`app/games/loaded_questions/player.rb`)
- Wrapper around `::Player` model
- Provides access to player document fields
- Methods: `guesser?`, `answer`, etc.

**LoadedQuestions::Game::Status** (`app/games/loaded_questions/game/status.rb`)
- Value object for game status
- Valid statuses: `polling`, `guessing`, `completed`

**LoadedQuestions::Game::Guesses** (`app/games/loaded_questions/game/guesses.rb`)
- Collection of guess objects
- Methods: `shuffled`, `to_a`, `find(player_id)`

**Broadcast Service Objects** (`app/games/loaded_questions/broadcast/*.rb`)

All broadcast services follow the same pattern:
- Initialize with `player_id:` keyword argument
- Implement `#call` method that triggers the broadcast
- Load necessary game/player data
- Use `PlayerChannel.broadcast_to(game.players)` to render and send turbo_stream updates
- Each has a corresponding turbo_stream view template

Available broadcasters:
- **PlayerConnected** - Triggered by PlayerChannel on first connection
- **PlayerCreated** - Triggered by PlayersController after player creation
- **PlayerDisconnected** - Triggered by PlayerChannel on last disconnect
- **AnswerUpdated** - Triggered by PlayersController after answer submission

## Development Patterns

### Adding a New Game

1. Add enum value to `Game::kind` in `app/models/game.rb`
2. Create namespace under `app/games/{game_name}/`
3. Implement wrapper classes with document accessor methods
4. Create form objects for validation
5. Build controller(s) with namespace
6. Add namespaced routes
7. Create broadcast service objects in `app/games/{game_name}/broadcast/`
8. Add case branch in `PlayerChannel#subscribed` and `#unsubscribed` for new game kind
9. Create RBS signatures in `sig/{game_name}.rbs`
10. Run `bin/steep check` to verify types

### Creating Broadcast Service Objects

When you need real-time updates for entity changes:

1. **Create the service object** (`app/games/{game_name}/broadcast/some_event.rb`):

```ruby
module GameName
  module Broadcast
    class SomeEvent
      def initialize(player_id:)
        @affected_player = ::Player.find(player_id)
      end

      def call
        game = Game.from_id(affected_player.game_id)
        player = game.find_player(affected_player.id)

        PlayerChannel.broadcast_to(game.players) do |current_player|
          ApplicationController.render(
            "game_name/players/some_event",
            formats: [:turbo_stream],
            locals: { current_player:, player: }
          )
        end
      end

      private

      attr_reader :affected_player
    end
  end
end
```

2. **Create the turbo_stream template** (`app/views/{game_name}/players/some_event.turbo_stream.erb`):

```erb
<%# Replace a single player in the list %>
<%= turbo_stream.replace dom_id(player) do %>
  <%= render partial: "game_name/players/player", locals: { player:, current_player: } %>
<% end %>

<%# Or update a section %>
<%= turbo_stream.update "some_section" do %>
  <%# Updated content %>
<% end %>
```

3. **Trigger from controller**:

```ruby
# After the entity state change
Broadcast::SomeEvent.new(player_id: player.id).call
```

**When to use broadcast service objects vs model methods**:
- Use **service objects** for granular entity updates (player joined, answer submitted)
- Use **model methods** (`game.broadcast_reload_game`) for full state reloads (phase transitions)

### Working with Documents

Game and player state is stored in JSON. Access via:

```ruby
# In wrapper classes
def document
  game.parsed_document  # Returns Hash with symbol keys
end

# Updating documents
document[:key] = value
game.document = document.to_json
game.save!
```

**Important**: `parsed_document` is memoized. Call `document=` to reset the cache.

### Form Objects

Form objects separate validation from models using the `Errors` class:

```ruby
class SomeForm
  attr_reader :field, :errors

  def initialize(field: nil)
    @field = NormalizedString.new(field)
    @errors = Errors.new
  end

  def valid?
    if (error = validate_field(field))
      errors.add(:field, message: error)
    end

    errors.empty?
  end

  private

  def validate_field(value)
    return "is too short" if value.length < 3
    return "is too long" if value.length > 100
  end
end
```

**Key points**:
- Initialize `@errors = Errors.new` (not `{}` or `[]`)
- Add errors with `errors.add(attribute, message:)` - attribute is positional, message is keyword
- Use `:base` attribute for non-field-specific errors
- Multiple errors can be added to the same attribute
- `errors.empty?` returns `true` when valid

Used in controllers:
```ruby
form = SomeForm.new(**params)
if form.valid?
  # Use form.field to build entities
else
  @form = form
  render :view, status: :unprocessable_content
end
```

Form errors integrate with `BootstrapFormBuilder` for automatic inline display with Bootstrap styling.

### Builder Objects

Builders construct complex entities:

```ruby
class NewGame
  def initialize(user:, player_name:, question:)
    @player = NewPlayer.new(user:, name: player_name, guesser: true)
    @question = question
  end

  def build
    game = ::Game.new
    game.kind = :game_type
    game.document = { /* initial state */ }.to_json
    game.players = [ player.build ]
    game
  end
end
```

## Testing

### Test Structure

```
test/
├── models/                    # Model unit tests
├── system/                    # System tests (Capybara)
│   └── loaded_questions/
│       └── games_test.rb
├── controllers/               # Controller tests
└── lib/                       # Lib tests
```

### Running Tests

```bash
# All tests
bin/rails test

# Specific test file
bin/rails test test/system/loaded_questions/games_test.rb

# Specific test
bin/rails test test/system/loaded_questions/games_test.rb:285
```

### System Test Patterns

System tests use multiple browser sessions to simulate multiple players:

```ruby
test "complete game flow" do
  # Create game as Alice (default session)
  visit new_loaded_questions_game_path
  fill_in "Player name", with: "Alice"
  click_on "Create New Game"

  game_slug = current_path.split("/").last

  # Join as Bob (separate session)
  using_session("bob") do
    visit new_loaded_questions_game_player_path(game_slug)
    fill_in "Name", with: "Bob"
    click_on "Create New Player"
  end

  # Back to Alice
  using_session("default") do
    click_on "Begin Guessing"
  end
end
```

### Test Conventions

- Test descriptions follow the pattern: `"#instance_method returns ..."` or `".class_method returns ..."`
- System tests use descriptive names: `"complete game flow with answer swapping"`
- Use `wait: 5` for assertions that depend on async updates
- Add `sleep 0.5` when waiting for DOM transitions

## Coding Conventions

### Ruby Style

- Follow Rails Omakase (enforced by RuboCop)
- If it can fit in one line, write definitions in a single line
- Use Ruby shorthand when setting keyword arguments with variables that have matching names:
  ```ruby
  # Good
  def foo(name:, age:)
    Person.new(name:, age:)
  end

  # Avoid
  def foo(name:, age:)
    Person.new(name: name, age: age)
  end
  ```

### View Conventions

- Use partials for reusable components
- Keep views focused on presentation, logic in controllers/models
- Use Turbo Frames for page sections that update independently
- Use confirmation modals for destructive or important actions

**Turbo Frame Response Pattern**:
When handling form submissions within Turbo Frames, prefer rendering the same view for both success and error states:

```ruby
# Controller action
def answer
  form = AnswerForm.new(answer: params[:answer])
  if form.valid?
    player.update_answer(form.answer)
    # Trigger broadcasts here
  end

  status = form.valid? ? :ok : :unprocessable_content
  render "polling_player", locals: { form: }, status:
end
```

This pattern:
- Simplifies code by eliminating separate turbo_stream templates
- Keeps all rendering logic in one place
- The Turbo Frame naturally updates with the new content
- Status codes properly indicate success/failure for proper browser behavior

### JavaScript Conventions

- Use Stimulus controllers for interactivity
- Keep controllers small and focused
- Use data attributes for configuration
- Prefer stimulus-components for common patterns (modals, etc.)

## Deployment

The app uses Kamal for Docker-based deployment:
```bash
bin/kamal deploy     # Deploy to production
```

Configuration: `config/deploy.yml`

## Related Applications

- **../loaded_questions**: Original Loaded Questions game (PostgreSQL, UUIDs, full implementation)
- **../burn_unit**: Original Burn Unit game (PostgreSQL, UUIDs, full implementation)

Refer to these for reference implementations when porting features. See `MIGRATION_REVIEW.md` for detailed comparison.
