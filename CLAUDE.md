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
npm run herb:lint app/views     # Lint HTML and ERB in views
```

## Project Overview

**Party** is a Rails 8 application - a composable, multi-game platform designed to host multiple party games under a single application. It uses a document-oriented architecture where game-specific state is stored in JSON documents, allowing different game types to coexist without schema changes.

### Migration Status

The app is being migrated from two standalone applications:
- `../loaded_questions` - A guessing/matching game (fully ported)
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
  ├── game.rb                    # Wrapper around ::Game model
  ├── player.rb                  # Wrapper around ::Player model
  ├── games_controller.rb        # Game-specific controller
  ├── players_controller.rb      # Player management
  ├── create_new_game.rb         # Builder for new game creation
  ├── create_new_round.rb        # Builder for starting new rounds
  ├── new_player.rb              # Builder for new player
  ├── new_game_form.rb           # Form for game creation
  ├── new_player_form.rb         # Form for player creation
  ├── new_round_form.rb          # Form for new round creation
  ├── answer_form.rb             # Form for answer submission
  ├── guessing_round_form.rb     # Form for starting guessing phase
  ├── completed_round_form.rb    # Form for completing round
  ├── broadcast/                 # Real-time broadcast service objects
  │   ├── player_connected.rb    # Player comes online
  │   ├── player_created.rb      # New player joins
  │   ├── player_disconnected.rb # Player goes offline
  │   ├── answer_updated.rb      # Player submits answer
  │   ├── round_created.rb       # New round started
  │   ├── guessing_round_started.rb  # Guessing phase begins
  │   ├── round_completed.rb     # Round ends
  │   └── answers_swapped.rb     # Guesser swaps answers
  └── game/
      ├── status.rb              # Value object for game state
      └── guesses.rb             # Domain model for guess collection
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
- Thread-safe using `Concurrent::Map` directly
- Provides `increment(player_id)`, `decrement(player_id)`, and `count(player_id)` methods
- Powers the "online?" indicator for players

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

Broadcast services follow two patterns depending on whether they're entity-specific or game-wide:

**Pattern 1: Player-Specific Broadcasts** (use `player_id`)
```ruby
class Broadcast::SomeEvent
  def initialize(player_id:)
    @affected_player = ::Player.find(player_id)
  end

  def call
    game = Game.from_id(affected_player.game_id)
    player = game.find_player(affected_player.id)

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

**Pattern 2: Game-Wide Broadcasts** (use `game_id`, often filtered to non-guessers)
```ruby
class Broadcast::SomeGameEvent
  def initialize(game_id:)
    @game_id = game_id
  end

  def call
    game = Game.from_id(game_id)

    PlayerChannel.broadcast_to(game.players) do |current_player|
      next if current_player.guesser?  # Often skip the guesser

      ApplicationController.render(
        "loaded_questions/games/some_event",
        formats: [:turbo_stream],
        locals: { game:, current_player: }
      )
    end
  end
end
```

**Available broadcasters** (`app/games/loaded_questions/broadcast/`):

**Player-specific** (initialize with `player_id:`):
- **PlayerConnected**: Updates player online status when they connect
- **PlayerCreated**: Adds new player to all players' lists
- **PlayerDisconnected**: Updates player offline status when they disconnect
- **AnswerUpdated**: Shows checkmark when player submits an answer

**Game-wide** (initialize with `game_id:`, typically skip guesser):
- **RoundCreated**: Notifies non-guessers that a new round has started
- **GuessingRoundStarted**: Transitions non-guessers to guessing phase
- **AnswersSwapped**: Updates non-guesser view when guesser swaps answers
- **RoundCompleted**: Transitions non-guessers to completed view

Each broadcaster:
1. Initializes with `player_id:` or `game_id:` keyword argument
2. Loads necessary game/player data
3. Uses `PlayerChannel.broadcast_to` to iterate through all online players
4. Renders a turbo_stream template for each recipient
5. Broadcasts individual updates via `Turbo::StreamsChannel`

**Usage in controllers**:
```ruby
# Player-specific events
Broadcast::PlayerCreated.new(player_id: player.id).call
Broadcast::AnswerUpdated.new(player_id: current_player.id).call

# Game-wide events
Broadcast::RoundCreated.new(game_id: game.id).call
Broadcast::GuessingRoundStarted.new(game_id: game.id).call
Broadcast::AnswersSwapped.new(game_id: game.id).call
Broadcast::RoundCompleted.new(game_id: game.id).call
```

#### Two Broadcasting Approaches

| Approach | When to Use | Example | Updates |
|----------|------------|---------|---------|
| **Player-Specific Broadcast Objects** | Individual player actions | Player joins, answers | Only affected players see changes |
| **Game-Wide Broadcast Objects** | Phase transitions | Round starts/ends, answers swapped | All/most players transition together |

**The application uses broadcast service objects exclusively for all real-time updates.**

### Type System (RBS)

Type signatures in `/sig/`:
- `models.rbs` - Core ActiveRecord models
- `lib.rbs` - Shared utilities (NormalizedString, PlayerConnections, Errors)
- `loaded_questions.rbs` - Complete game module types
- `controllers.rbs` - Controller instance variables
- `external.rbs` - Third-party library types

**Key patterns**:
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

**Phase 3: Completed (Status: "completed")**
1. Shows correct matches vs guesser's guesses with visual indicators
   - Green background for correct matches
   - Red background for incorrect matches
2. Displays guesser's score (count of correct matches)
3. Non-guessers see "Create Next Turn" button to start a new round

**Phase 4: New Round**
1. Any non-guesser can start a new round by providing a question
2. The player who creates the round becomes the new guesser
3. All players' documents are reset (active: true, answer: "", guesser: true/false)
4. Game returns to polling phase with the new question

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
  active: true,   # Whether player is active in current round
  guesser: true,  # or false - role in current round
  answer: "Blue"  # or "" if not yet submitted
}
```

### Implementation Status

**✅ Fully Implemented**:
- **Game Creation**: Initial game with question and first guesser
- **Player Management**: Joining with unique names, real-time updates
- **Polling Phase**: Answer submission with real-time checkmarks
- **Guessing Phase**: Shuffled answer display, drag-and-drop swapping
- **Completed Phase**: Score calculation, correct/incorrect indicators
- **Multiple Rounds**: Players can start new rounds with rotating guesser
- **Real-time Updates**: Player online/offline status via WebSocket
- **Confirmation Modals**: For phase transitions (Begin Guessing, Complete Matching)
- **Comprehensive Broadcasting**: 8 different broadcast events for all game state changes
- **System Tests**: Complete coverage of game flow and interactions

**❌ Not Yet Implemented**:
- Score tracking across rounds (currently only shows score for current round)
- Game history/statistics
- Player removal (can join but can't leave)
- Hide answers toggle for guesser
- Round time limits
- Answer editing after submission

### Key Classes

**LoadedQuestions::Game** (`app/games/loaded_questions/game.rb`)
- Wrapper around `::Game` model
- Provides access to game document fields
- Key methods: `question`, `status`, `guesses`, `guesser`, `players`, `player_for(user)`, `player_for!(user)`, `find_player(id)`, `swap_guesses(player_id1:, player_id2:)`, `update_status(new_status)`, `slug`, `to_model`

**LoadedQuestions::Player** (`app/games/loaded_questions/player.rb`)
- Wrapper around `::Player` model
- Provides access to player document fields
- Key methods: `active?`, `guesser?`, `answer`, `answered?`, `name`, `online?`, `update_answer(answer)`, `to_model`

**LoadedQuestions::Game::Status** (`app/games/loaded_questions/game/status.rb`)
- Value object for game status
- Valid statuses: `polling`, `guessing`, `completed`
- Provides predicate methods: `polling?`, `guessing?`, `completed?`

**LoadedQuestions::Game::Guesses** (`app/games/loaded_questions/game/guesses.rb`)
- Collection of guess objects with swap and scoring capabilities
- Key methods: `find(player_id)`, `swap(player_id1:, player_id2:)`, `score`, `size`, `as_json`
- Includes `Enumerable` for iteration
- Nested `GuessedAnswer` class with `correct?` method for scoring

**Form Objects** (`app/games/loaded_questions/*_form.rb`)
All forms follow the same pattern with `valid?` method and `errors` attribute:
- **NewGameForm** - Validates game creation (player name + question)
- **NewPlayerForm** - Validates player joining (unique name)
- **AnswerForm** - Validates answer submission (length constraints)
- **GuessingRoundForm** - Validates transition to guessing (min 2 answers)
- **CompletedRoundForm** - Validates round completion (must be in guessing phase)
- **NewRoundForm** - Validates new round creation (must be completed, valid question)

**Builder Objects**
- **CreateNewGame** - Constructs game with initial player/guesser and question
- **CreateNewRound** - Resets game state and player documents for new round
- **NewPlayer** - Builds player with game-specific document structure

**Broadcast Service Objects** (`app/games/loaded_questions/broadcast/*.rb`)

Two patterns: player-specific (use `player_id:`) and game-wide (use `game_id:`):

**Player-specific broadcasters**:
- **PlayerConnected** - Triggered by PlayerChannel on first connection
- **PlayerCreated** - Triggered by PlayersController after player creation
- **PlayerDisconnected** - Triggered by PlayerChannel on last disconnect
- **AnswerUpdated** - Triggered by PlayersController after answer submission

**Game-wide broadcasters** (typically skip guesser):
- **RoundCreated** - Triggered after new round creation
- **GuessingRoundStarted** - Triggered when guesser starts guessing phase
- **AnswersSwapped** - Triggered when guesser swaps answers
- **RoundCompleted** - Triggered when guesser completes the round

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

### Routes

The application uses namespaced routes for game-specific functionality:

```ruby
namespace :loaded_questions do
  resources :games, only: %i[create new show] do
    member do
      get :new_round              # Form for creating new round
      post :create_round          # Create new round with new guesser
      patch :completed_round      # Complete current round (guesser only)
      patch :guessing_round       # Start guessing phase (guesser only)
      patch :swap_guesses         # Swap answer positions (guesser only)
    end
    resource :player, only: %i[create new edit update] do
      member do
        patch :answer             # Submit/update answer (non-guesser only)
      end
    end
  end
end
```

**Key routes**:
- `GET /loaded_questions/games/new` - New game form
- `POST /loaded_questions/games` - Create game
- `GET /loaded_questions/games/:id` - Show game (main view, renders different partials based on status and role)
- `GET /loaded_questions/games/:id/new_round` - New round form (non-guesser only, after completion)
- `POST /loaded_questions/games/:id/create_round` - Create new round
- `PATCH /loaded_questions/games/:id/guessing_round` - Start guessing phase
- `PATCH /loaded_questions/games/:id/completed_round` - Complete round
- `PATCH /loaded_questions/games/:id/swap_guesses` - Swap answer positions
- `GET /loaded_questions/games/:id/player/new` - New player form
- `POST /loaded_questions/games/:id/player` - Create player (join game)
- `PATCH /loaded_questions/games/:id/player/answer` - Submit answer

### Creating Broadcast Service Objects

When you need real-time updates for entity or game state changes, choose the appropriate pattern:

**Pattern 1: Player-Specific Broadcasts** (for entity updates like player actions)

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
```

3. **Trigger from controller**:

```ruby
Broadcast::SomeEvent.new(player_id: player.id).call
```

**Pattern 2: Game-Wide Broadcasts** (for phase transitions, typically skip guesser)

1. **Create the service object** (`app/games/{game_name}/broadcast/some_game_event.rb`):

```ruby
module GameName
  module Broadcast
    class SomeGameEvent
      def initialize(game_id:)
        @game_id = game_id
      end

      def call
        game = Game.from_id(game_id)

        PlayerChannel.broadcast_to(game.players) do |current_player|
          next if current_player.guesser?  # Skip if needed

          ApplicationController.render(
            "game_name/games/some_event",
            formats: [:turbo_stream],
            locals: { game:, current_player: }
          )
        end
      end

      private

      attr_reader :game_id
    end
  end
end
```

2. **Create the turbo_stream template** (`app/views/{game_name}/games/some_event.turbo_stream.erb`):

```erb
<%# Update the main game frame %>
<%= turbo_stream.replace "round_frame" do %>
  <%= render "game_name/games/new_phase_frame", game:, current_player: %>
<% end %>
```

3. **Trigger from controller**:

```ruby
Broadcast::SomeGameEvent.new(game_id: game.id).call
```

**When to use each pattern**:
- Use **player-specific broadcasts** (Pattern 1) for entity updates: player joined, player answered, player connected/disconnected
- Use **game-wide broadcasts** (Pattern 2) for phase transitions: round started, round completed, answers swapped

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

Builders construct complex entities with proper document initialization:

```ruby
class CreateNewGame
  def initialize(user:, player_name:, question:)
    @user = user
    @player_name = player_name
    @question = question
  end

  def call
    game = ::Game.new(
      kind: :loaded_questions,
      document: game_document.to_json
    )

    player = ::Player.new(
      game:,
      user:,
      name: player_name,
      document: player_document.to_json
    )

    game.players << player

    ::ActiveRecord::Base.transaction do
      game.save!
      player.save!
    end

    Game.from_id(game.id)  # Return wrapped game
  end

  private

  def game_document
    {
      question: question,
      status: Game::Status.polling,
      guesses: []
    }
  end

  def player_document
    {
      active: true,
      guesser: true,
      answer: ""
    }
  end
end
```

**Key points**:
- Builders return saved, persisted objects (not just built objects)
- Use transactions when creating multiple related objects
- Initialize documents with proper structure for the game type
- Return wrapped objects (e.g., `LoadedQuestions::Game`) not raw ActiveRecord models

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
