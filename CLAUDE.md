# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Quick Start

```bash
bin/setup              # Install deps, prepare DB, start dev server
bin/dev                # Start dev server (Procfile.dev)
bin/rails test         # Run all tests (parallelized)
bin/steep check        # Type check with RBS (run before committing)
```

## Project Overview

**Party** is a Rails 8 application - a composable, multi-game platform using document-oriented architecture where game-specific state is stored in JSON documents, allowing different game types to coexist without schema changes.

**Tech Stack**: Rails 8, Hotwire (Turbo & Stimulus), Bootstrap 5, SQLite, RBS + Steep, Solid Cache/Queue/Cable, Kamal

**Testing**: Parallelized test suite with SimpleCov coverage, Mocha for stubbing.

## Core Architecture

### Database Schema

Document-oriented design: **Games** have `kind` enum and `document` json for all game state. **Players** have `game_id`, `user_id`, `name`, and `document` json for player state. Validates `user_id` and name (case-insensitive) uniqueness within game. **Users** use cookie-based identification without authentication.

### Game Implementation Pattern

Games live under `/app/games/{game_name}/`:

**Aggregate Wrappers** (`game.rb`, `player.rb`): AR-ignorant domain objects. Hold an immutable `Document` value object plus identity (`id`); mutations call `document.with(...)`. Implement `.build` for construction; identity methods (`to_param`, `to_global_id`, `model_name`) delegate to `::Game`/`::Player` for Rails interop.
**Persistence** (`game_repo.rb`, `game_mapping.rb`): The shared `GameStore` (`app/lib/`) owns the AR mechanics (query, transaction, player diffing) and is the only thing that touches `::Game`/`::Player`. Each game's `game_repo.rb` is a one-line constant — `GameRepo = GameStore.new(mapping: GameMapping.new)` — and `game_mapping.rb` supplies the per-game `kind` plus `load_game`/`load_player` construction. `GameStore.generate_game_id`/`generate_player_id` mint ids.
**Controllers**: Namespaced, reference the `GameRepo` constant, handle Turbo Frame responses, use form objects, trigger broadcasts.
**Form Objects**: Validation with `Errors` collection, return `#valid?`. `NewPlayerForm`/`EditPlayerForm` are game-agnostic and shared in `app/forms/`; game-specific forms live in the namespace.
**Broadcasts** (`broadcast/*.rb`): Per-event service objects that fan out Turbo Streams to online players.
**Adapter** (`adapter.rb`): Implements the `_GameAdapter` interface; `PlayerChannel` dispatches connection events through it.
**Domain Models** (`game/`, `player/`): Value objects for `Document`, `Status`, and game-specific collections.

### Shared Infrastructure (`/app/lib/`)

**NormalizedString**: Immutable value object for text (NFKC normalization, case-insensitive comparison)
**PlayerConnections**: Thread-safe singleton tracking online players with `increment/decrement/count`
**Errors**: Lightweight error container with `#add(attribute, message:)`, `#added?`, `#empty?`, `#[]`
**PlayerBroadcaster**: Iterates a player collection, sends Turbo Stream content to each online player via `Turbo::StreamsChannel`, and skips when the block returns `nil`.
**LengthValidator**: Field-aware min/max length validator used by aggregates and forms.

### Real-time Communication

**PlayerChannel**: GlobalID-based streams with connection tracking and first/last connection optimization. Dispatches `on_player_connected` / `on_player_disconnected` to a per-game adapter (`LoadedQuestions::Adapter`, `BurnUnit::Adapter`) selected via `player.game.kind`.

**Broadcast Patterns**: Each broadcast is a small class under `{game}/broadcast/`. Initialize with the wrapper aggregates it needs (`game:`, optionally `player:`), build the player set, and use `PlayerBroadcaster` to render a turbo_stream template per online recipient. Skip with `next` (e.g., the guesser, or the originating player).

```ruby
Broadcast::PlayerCreated.new(game:, player:).call
Broadcast::RoundCreated.new(game:).call
```

### Type System (RBS)

Type signatures in `/sig/`: `models.rbs`, `lib.rbs` (incl. generic `GameStore`), `forms.rbs`, `controllers.rbs`, `channels.rbs`, `validators.rbs`, `external.rbs`, `loaded_questions.rbs`, `burn_unit.rbs`, `codenames.rbs`.

**Always run `bin/steep check` before committing.**

## Loaded Questions Game

**Phases**: Polling (submit answers) → Guessing (drag-and-drop assignment) → Completed (scored, new round)

**Documents**: Game has `{ question, status, guesses_data }`, Player has `{ answer, guesser, score }`

**Key Classes**:
- Aggregates: `Game` (`.build`, `question`, `status`, `guesses`, `players`, `add_player`, `assign_guess`, `begin_guessing`, `complete_round`, `start_new_round`), `Player` (`answer`, `guesser?`, `online?`, `score`)
- Persistence: `GameRepo` (a `GameStore` constant), `GameMapping` (`kind`, `load_game`, `load_player`)
- Value Objects: `Game::Document`, `Game::Status` (`polling?`, `guessing?`, `completed?`), `Game::Guesses` (`assign`, `score`, `complete?`, `for_completed_view`), `Game::GuessedAnswer`, `Game::Guesses::CompletedGuess` (`correct?`)
- Forms: `NewGameForm`, `NewPlayerForm`, `EditPlayerForm`, `AnswerForm`, `NewRoundForm`, `GuessingRoundForm`, `CompletedRoundForm`
- Broadcasts (9): `PlayerCreated`, `PlayerConnected`, `PlayerDisconnected`, `PlayerNameUpdated`, `AnswerCreated`, `RoundCreated`, `GuessingRoundStarted`, `GuessesUpdated`, `RoundCompleted`
- Questions: Loaded from `config/loaded_questions/questions.yml` singleton

## Burn Unit Game

**Phases**: Polling (players submit candidates for the prompt) → Completed (judge picked a winner, scores updated)

**Roles**: One **judge** per round (rotates), other players are **playing**.

**Key Classes**:
- Aggregates: `Game` (`.build`, `question`, `status`, `judge`, `players`, `add_player`, `start_new_round`, ...), `Player` (`judge?`, `playing?`, `vote`, `online?`, `score`)
- Persistence: `GameRepo` (a `GameStore` constant), `GameMapping`
- Forms: `NewGameForm`, `NewPlayerForm`, `EditPlayerForm`, `VoteForm`, `NewRoundForm`, `CompletedRoundForm`
- Broadcasts: `PlayerCreated`, `PlayerConnected`, `PlayerDisconnected`, `PlayerNameUpdated`, `CandidateAdded`, `VoteCreated`, `RoundCreated`, `RoundCompleted`
- Questions: Loaded from `config/burn_unit/questions.yml` singleton

## Codenames Game

A digital companion for in-person play (a faithful 5×5 / two-team Codenames). **Clues are spoken aloud and never entered or tracked** — the app owns the board, the secret key, reveal tracking, automatic turn switching, and win detection.

**Phases**: Setup (lobby: pick team + role) → Playing (operatives reveal cards) → Completed (a team won or the assassin was hit)

**Roles**: Each team (red/blue) has exactly **one spymaster** (sees the key) and one or more **operatives** (reveal cards). Board key per game: **9 starting-team agents, 8 other-team, 7 bystanders, 1 assassin**. Only the starting team's spymaster can start; teams/roles lock once playing (a mid-game joiner may pick any team as an operative). No spectators.

**Documents**: Game has `{ status, starting_team, current_team, winner, board }` (board = 25 `{ word, identity, revealed }`); Player has `{ team, spymaster }`. `current_team` is non-nil from construction (initialized to `starting_team`).

**Key Classes**:
- Aggregates: `Game` (`.build`, `board`, `status`, `current_team`, `starting_team`, `winner`, `players_on`, `spymaster_for`, `operatives`, `add_player`, `join_team`, `start_game`, `reveal`, `pass_turn`, `start_new_game`), `Player` (`team`, `spymaster?`, `operative?`, `online?`)
- Value Objects: `Team` (top-level `Codenames::Team`, shared by game + player), `Game::Status` (`setup?`/`playing?`/`completed?`), `Game::Identity` (red/blue/bystander/assassin), `Game::Card`, `Game::Board` (`generate`, `reveal`, `remaining`, `all_revealed?`)
- Persistence: `GameRepo` (a `GameStore` constant), `GameMapping`
- Forms: `NewGameForm`, `NewPlayerForm`, `EditPlayerForm`, `JoinTeamForm`, `StartGameForm`
- Broadcasts: `PlayerCreated`, `PlayerConnected`, `PlayerDisconnected`, `PlayerNameUpdated`, `TeamUpdated`, `GameStarted`, `BoardUpdated`, `NewGameStarted`
- Reveals/pass use `button_to` + Turbo (reveal carries `data-turbo-confirm`); a `spymaster-key` Stimulus controller toggles the key (hidden by default)
- Words: Loaded from `config/codenames/words.yml` singleton (`Words.instance.sample(25)`)

## Development Patterns

### Working with Aggregate Wrappers

```ruby
repo = LoadedQuestions::GameRepo
game = LoadedQuestions::Game.build(question:)        # Construct with .build
game.add_player(user_id:, name:, guesser: true)     # Mutations live on the aggregate
game.begin_guessing                                  # Phase transitions are aggregate methods
repo.save(game)                                      # Repo persists game + all players in a transaction
game = repo.find(id)                                 # Reload via repo (uses .strict_loading)
```

Aggregates do **not** expose plain attribute setters for document fields — state changes flow through named operations (`start_new_round`, `assign_guess`, `complete_round`) that swap in a new `Document` via `document.with(...)`. Aggregates never touch ActiveRecord; only `GameStore` does (via the per-game mapping).

### Form Objects

Use `Errors.new` (not `{}` or `[]`), call `errors.add(attribute, message:)` where attribute is positional and message is keyword. Use `:base` for non-field errors. Return `#valid?` checking `errors.empty?`.

### Phase Transitions

Single-method service objects have been collapsed into aggregate methods. To transition phases, call the method on the `Game` aggregate (`begin_guessing`, `complete_round`, `start_new_round`, `assign_guess`) and then `repo.save(game)`. Controllers handle that orchestration; broadcasts fire after the save.

### Creating Broadcast Service Objects

Initialize with the wrapper aggregates the broadcast needs (`game:`, optionally `player:`). Compose a `PlayerBroadcaster` with `game.players` and call `broadcast` with a block yielding `current_player`. Skip recipients with `next`. Render turbo_stream templates with locals.

```ruby
players = game.players
PlayerBroadcaster.new(players:).broadcast do |current_player|
  next if current_player.guesser?
  ApplicationController.render(
    "loaded_questions/games/round_created",
    formats: [:turbo_stream],
    locals: { game:, current_player: }
  )
end
```

### Adding a New Game

1. Add enum value to `Game::kind` in `app/models/game.rb`
2. Create namespace under `app/games/{game_name}/`
3. Implement core classes:
   - Aggregate wrappers (`game.rb`, `player.rb`) with `.build` and document-mutation methods
   - Value objects in `game/` and `player/` (Document, Status, etc.)
   - `game_mapping.rb` (`kind`, `load_game`, `load_player`) + `game_repo.rb` (`GameRepo = GameStore.new(mapping: GameMapping.new)`) — construction is per-game; the shared `GameStore` does the AR work
   - Form objects for game-specific validation (`*_form.rb`); reuse shared `NewPlayerForm`/`EditPlayerForm`
   - Controllers (`games_controller.rb`, `players_controller.rb`)
4. Add namespaced routes in `config/routes.rb`
5. Create broadcast service objects in `broadcast/` directory
6. Create `adapter.rb` implementing the `_GameAdapter` interface (`on_player_connected` / `on_player_disconnected`) and add a branch in `PlayerChannel#adapter` for the new game kind
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

Include `Turbo::Broadcastable::TestHelper`, mark players online with `PlayerConnections.instance.increment(player_id)`. Pass the wrapper aggregate directly to the assertion (no `.to_model` — the wrapper itself is broadcastable):

```ruby
assert_turbo_stream_broadcasts alice, count: 1 do
  Broadcast::SomeEvent.new(game:, player: alice).call
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

Per-game prefixes: `lq_*` for Loaded Questions, `bu_*` for Burn Unit. Factories build aggregate wrappers; persist with `repo.save(game)`.

Loaded Questions: `lq_game` (base), `lq_polling_game`, `lq_matching_game` (guessing phase), `lq_completed_game`. Traits: `:with_guesser`, `:with_players`, `:with_answers`.

Burn Unit: `bu_game` (base), `bu_polling_game`, `bu_completed_game`. Traits: `:with_judge`, `:with_players`.

```ruby
game = create(:lq_polling_game, player_names: %w[Alice Bob])
game.players.find(&:guesser?)             # Find guesser
LoadedQuestions::GameRepo.save(game)  # Persist mutations
```

## Coding Conventions

**Ruby**: Follow Rails Omakase (RuboCop). Never use single-letter vars. Use keyword shorthand (`name:` not `name: name`), block shorthand (`find(&:guesser?)`). Use `# @dynamic` for RBS attr_readers. Wrap text in `NormalizedString.new`.

**Views**: Turbo Frames for sections, Turbo Streams for real-time. Render same view for success/error with `:ok` or `:unprocessable_content` status. Lint with `yarn run herb:lint app`.

**JavaScript**: Small Stimulus controllers, data attributes for config.

**Routes**: Namespace games, use member routes for actions, singular `resource :player` within game.

## Deployment

`bin/kamal deploy` deploys to production (config: `config/deploy.yml`).
