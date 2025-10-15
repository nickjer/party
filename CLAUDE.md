# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Rails 8 application called **Party** - a composable, multi-game platform designed to host multiple party games under a single application. It uses a document-oriented architecture where game-specific state is stored in JSON documents, allowing different game types to coexist without schema changes.

The app is actively being migrated from two standalone applications:
- `../loaded_questions` - A guessing/matching game (partially ported)
- `../burn_unit` - A voting game (not yet ported)

See `MIGRATION_REVIEW.md` for a comprehensive analysis of the migration status.

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
```

### Testing
```bash
bin/rails test                           # Run all tests
bin/rails test test/models/game_test.rb  # Run specific test file
bin/rails test test/system               # Run system tests
```

### Type Checking (RBS + Steep)
```bash
bin/steep check         # Type check the entire application
bin/steep watch         # Watch mode for continuous type checking
```

Type signatures are in `/sig/` directory. The project uses RBS extensively for type safety.

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

JavaScript source: `app/javascript/`
Output: `app/assets/builds/`

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
  └── game/
      ├── status.rb           # Value object for game state
      └── guesses.rb          # Domain model for guess collection
```

**Key principles**:
1. Wrapper classes encapsulate document JSON parsing
2. Form objects handle validation without touching models
3. Builder objects construct complex entities
4. Controllers are namespaced (e.g., `LoadedQuestions::GamesController`)
5. Routes are namespaced (e.g., `namespace :loaded_questions`)

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

### Real-time Communication

**GameChannel** (`app/channels/game_channel.rb`):
- Subscribes players to game-specific Turbo Streams
- Tracks player connections (increment on subscribe, decrement on unsubscribe)
- Broadcasts reload events to all players in a game

**Broadcasting pattern**:
```ruby
game.broadcast_reload_game      # Reloads game state for all players
game.broadcast_reload_players   # Updates player list for all players
```

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

Always run `bin/steep check` before committing changes.

## Current Implementation Status

### Loaded Questions (Partially Implemented)

**Working**:
- Game creation with initial question
- Player joining
- Answer submission (polling phase)
- Transition to guessing phase (answers shuffled)
- Display of shuffled answers
- Real-time player online/offline indicators

**Not Yet Implemented**:
- Guess submission (matching answers to players)
- Answer swapping backend (JS controller exists, no endpoint)
- Round completion and results display
- Multiple rounds per game
- Score tracking across rounds
- Starting new turns/rotating guesser
- Player removal
- Hide answers toggle

### Burn Unit (Not Started)

No code exists yet. See `MIGRATION_REVIEW.md` section 5.5 for recommended structure.

## Development Patterns

### Adding a New Game

1. Add enum value to `Game::kind` in `app/models/game.rb`
2. Create namespace under `app/games/{game_name}/`
3. Implement wrapper classes with document accessor methods
4. Create form objects for validation
5. Build controller(s) with namespace
6. Add namespaced routes
7. Create RBS signatures in `sig/{game_name}.rbs`
8. Run `bin/steep check` to verify types

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

Form objects separate validation from models:

```ruby
class SomeForm
  attr_reader :field, :errors

  def initialize(field: nil)
    @field = NormalizedString.new(field)
    @errors = {}
  end

  def valid?
    # Validation logic, populate @errors
    errors.empty?
  end
end
```

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

## JavaScript/Stimulus Controllers

Controllers in `app/javascript/controllers/`:

**swap_controller.js**:
- Uses SortableJS with Swap plugin
- Enables drag-and-drop reordering
- Sends swap events via fetch to backend endpoint
- Not yet connected to backend for Loaded Questions

**hello_controller.js**:
- Example Stimulus controller

When adding new controllers:
1. Create in `app/javascript/controllers/`
2. Use Stimulus naming conventions
3. Import automatically via `controllers/index.js`

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
- Test descriptions should follow the pattern: `"#instance_method returns ..."` or `".class_method returns ..."`
- If it can fit in one line then write definitions in a single line
- Use ruby shorthand when setting keyword arguments with variables that have a matching name
