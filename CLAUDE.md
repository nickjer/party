# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Quick Start

```bash
bin/rails db:setup    # Create database and load schema
bin/dev               # Start dev server (Procfile.dev)
bin/rails test        # Run all tests (parallelized)
bin/steep check       # Type check with RBS (run before committing)
```

## Project Overview

**Party** is a Rails 8 application - a composable, multi-game platform using document-oriented architecture where game-specific state is stored in JSON documents, allowing different game types to coexist without schema changes.

**Tech Stack**: Rails 8, Hotwire (Turbo & Stimulus), SQLite, RBS + Steep, Tailwind CSS, Solid Cache/Queue/Cable, Kamal

**Testing**: Parallelized test suite with SimpleCov coverage, Mocha for stubbing.

## Core Architecture

### Database Schema

Document-oriented design: **Games** have `kind` enum and `document` json for all game state. **Players** have `game_id`, `user_id`, `name`, and `document` json for player state. Validates `user_id` and name (case-insensitive) uniqueness within game. **Users** use cookie-based identification without authentication.

### Game Implementation Pattern

Games live under `/app/games/{game_name}/`:

**Wrapper Classes** (game.rb, player.rb): Encapsulate models, provide domain methods, use `parsed_document` memoization, implement `.build` pattern
**Controllers**: Namespaced, handle Turbo Frame responses, use form objects, trigger broadcasts
**Service Objects**: Builders for construction, state transitions for phase changes, broadcasts for real-time updates
**Form Objects**: Validation with `Errors` collection, return `#valid?`
**Domain Models**: Value objects for status and collections

### Shared Infrastructure (`/app/lib/`)

**NormalizedString**: Immutable value object for text (NFKC normalization, case-insensitive comparison)
**PlayerConnections**: Thread-safe singleton tracking online players with `increment/decrement/count`
**Errors**: Lightweight error container with `#add(attribute, message:)`, `#added?`, `#empty?`, `#[]`

### Real-time Communication

**PlayerChannel**: GlobalID-based streams with connection tracking, first/last connection optimization. Custom `PlayerChannel.broadcast_to(players)` iterates online players and renders Turbo Streams.

**Broadcast Patterns**:
1. **Player-Specific** (`player_id:`): Individual actions (joins, answers, connects)
2. **Game-Wide** (`game_id:`): Phase transitions (round starts/ends), typically skip guesser

```ruby
Broadcast::PlayerCreated.new(player_id:).call
Broadcast::RoundCreated.new(game_id:).call
```

### Type System (RBS)

Type signatures in `/sig/`: `models.rbs`, `lib.rbs`, `loaded_questions.rbs`, `controllers.rbs`, `external.rbs`

**Always run `bin/steep check` before committing.**

## Loaded Questions Game

**Phases**: Polling (submit answers) → Guessing (match via drag-drop) → Completed (scored, new round)

**Documents**: Game has `{ question, status, guesses }`, Player has `{ answer, guesser, score }`

**Key Classes**:
- Wrappers: Game (`.build`, `.find`, `question`, `status`, `guesses`, `players`, `swap_guesses`), Player (`answer`, `guesser?`, `online?`, `score`)
- Value Objects: Status (`polling?`, `guessing?`, `completed?`), Guesses (`swap`, `score`), GuessedAnswer (`correct?`)
- Service Objects: CreateNewGame, CreateNewRound, BeginGuessingRound, CompleteRound
- Forms: NewGameForm, NewPlayerForm, AnswerForm, EditPlayerForm, NewRoundForm, GuessingRoundForm, CompletedRoundForm
- Broadcasts (9): PlayerCreated/Connected/Disconnected/NameUpdated/AnswerUpdated, RoundCreated/GuessingRoundStarted/AnswersSwapped/RoundCompleted
- Questions: Loaded from `config/loaded_questions/questions.yml` singleton

## Development Patterns

### Working with Wrapper Classes

```ruby
game = LoadedQuestions::Game.build(question:)  # Build with .build
game.question = new_question  # Setters update @ivar and model.document
game.save!  # Saves model and all cached players in transaction
game = LoadedQuestions::Game.find(id)  # Reload with .strict_loading
```

### Form Objects

Use `Errors.new` (not `{}` or `[]`), call `errors.add(attribute, message:)` where attribute is positional and message is keyword. Use `:base` for non-field errors. Return `#valid?` checking `errors.empty?`.

### Service Objects

**Builders**: Initialize with params, return built (unsaved) wrappers, caller saves. Example: `CreateNewGame.new(user_id:, player_name:, question:).call`

**State Transitions**: Initialize with wrapper, validate state, modify state, return wrapper (caller saves). Example: `BeginGuessingRound.new(game:).call`

### Creating Broadcast Service Objects

Initialize with IDs (`player_id:` or `game_id:`), load wrapper with `.find`, use `PlayerChannel.broadcast_to(game.players)` with block yielding `current_player`. Skip players with `next` if needed. Render turbo_stream templates with locals.

```ruby
PlayerChannel.broadcast_to(game.players) do |current_player|
  next if current_player.guesser?
  ApplicationController.render("path/to/template", formats: [:turbo_stream], locals: { game:, current_player: })
end
```

### Adding a New Game

1. Add enum value to `Game::kind` in `app/models/game.rb`
2. Create namespace under `app/games/{game_name}/`
3. Implement core classes:
   - Wrapper classes (game.rb, player.rb) with `.build` and `.find`
   - Form objects for validation (*_form.rb)
   - Service objects for building and state transitions
   - Controllers (games_controller.rb, players_controller.rb)
4. Add namespaced routes in `config/routes.rb`
5. Create broadcast service objects in `broadcast/` directory
6. Add case branch in `PlayerChannel#subscribed` and `#unsubscribed` for new game kind
7. Create RBS signatures in `sig/{game_name}.rbs`
8. Create test files mirroring structure in `test/games/{game_name}/`
9. Add factory definitions in `test/factories/`
10. Run `bin/steep check` and `bin/rails test`

## Testing

### Running Tests

```bash
bin/rails test                        # All tests (parallelized)
bin/rails test test/games/           # Directory
bin/rails test path/to/file_test.rb  # Specific file
bin/rails test path/to/file_test.rb:10  # Specific line
```

### Test Conventions

**Descriptions**: Instance `"#method"`, class `".method"`, system `"descriptive flow"`. Assert "when X" in test body.

**Assertions**: Use `assert_predicate`/`assert_not_predicate` for predicates, `assert_not` (not `refute`), `assert_dom`/`assert_not_dom` for DOM. System tests: `wait: 5` for async, `sleep 0.5` for transitions.

**Helpers**: `sign_in(user_id)`, `reload(game:)`. Global setup stubs fresh PlayerConnections per test.

### Testing Broadcast Service Objects

Include `Turbo::Broadcastable::TestHelper`, mark players online with `PlayerConnections.instance.increment(player_id)`. Use assertions:

```ruby
assert_turbo_stream_broadcasts player.to_model, count: 1 do
  Broadcast::SomeEvent.new(player_id:).call
end
```

### System Test Pattern

Use `using_session` for multi-player scenarios. Get game ID from `current_path.split("/").last`.

```ruby
game_id = current_path.split("/").last
using_session("bob") do
  visit new_loaded_questions_game_player_path(game_id)
end
```

### Factories

`lq_game` factory builds wrappers. Nested factories: `lq_polling_game` (with players), `lq_matching_game` (guessing phase), `lq_completed_game` (scored). Traits: `:with_guesser`, `:with_players`, `:with_answers`.

```ruby
create(:lq_polling_game, player_names: %w[Alice Bob])
create(:lq_matching_game, player_names: %w[Alice Bob])
game.players.find(&:guesser?)  # Find guesser
game.save!  # Saves wrapper and cached players
```

## Coding Conventions

**Ruby**: Follow Rails Omakase (RuboCop). Never use single-letter vars. Use keyword shorthand (`name:` not `name: name`), block shorthand (`find(&:guesser?)`). Use `# @dynamic` for RBS attr_readers. Wrap text in `NormalizedString.new`.

**Views**: Turbo Frames for sections, Turbo Streams for real-time. Render same view for success/error with `:ok` or `:unprocessable_content` status. Lint with `yarn run herb:lint app`.

**JavaScript**: Small Stimulus controllers, data attributes for config.

**Routes**: Namespace games, use member routes for actions, singular `resource :player` within game.

## Deployment

`bin/kamal deploy` deploys to production (config: `config/deploy.yml`).
