# Comprehensive Review: Party, Loaded Questions, and Burn Unit Applications

## Executive Summary

I've completed a thorough review of all three Rails applications. The **Party** app represents an ambitious architectural evolution from the two standalone games (**Loaded Questions** and **Burn Unit**) into a composable, multi-game platform. The migration is partially complete for Loaded Questions, with significant functionality remaining to port.

---

## 1. Party App Architecture (Composable Platform)

### Core Design Philosophy
The Party app uses a **document-oriented, game-agnostic schema** with game-specific logic implemented as namespaced modules.

### Database Schema
- **Games table**: `kind` (enum), `slug`, `document` (JSON field storing all game state)
- **Players table**: `game_id`, `user_id`, `name`, `document` (JSON field storing player-specific state)
- **Users table**: Minimal, just tracks `last_seen_at`

Key insight: All game-specific state lives in JSON `document` fields, making the schema highly flexible.

### Shared Infrastructure
**Location**: `/app/lib/`

1. **NormalizedString** (`app/lib/normalized_string.rb`)
   - Handles text normalization (NFKC, squish, remove control chars)
   - Case-insensitive comparison
   - Used for player names and answers

2. **PlayerConnections** (`app/lib/player_connections.rb`)
   - Singleton tracking online player connections
   - Uses thread-safe ScoreMap for concurrent access
   - Powers the "online?" indicator

3. **ScoreMap** (`app/lib/score_map.rb`)
   - Thread-safe counter using `Concurrent::Map`
   - Used for connection tracking and could be reused for scoring

### Game Implementation Pattern
Games live under `/app/games/{game_name}/` with:
- Wrapper classes (e.g., `LoadedQuestions::Game`, `LoadedQuestions::Player`)
- Form objects for validation
- Builder objects for entity creation
- Controllers namespaced by game

### RBS Type Coverage
Excellent type signatures in `/sig/`:
- **models.rbs**: Core ActiveRecord models
- **lib.rbs**: Shared utilities
- **loaded_questions.rbs**: Complete type coverage for the game module
- Uses advanced features like generic types (`ScoreMap[K]`) and structural typing

---

## 2. Loaded Questions App (Original Implementation)

### Database Schema
Rich relational model with 7 tables:
- **games**: Just status (playing/completed)
- **players**: name, soft-delete (`deleted_at`)
- **rounds**: question, guesser, order, status (polling/matching/completed), hide_answers flag
- **participants**: Join table between players and rounds
- **answers**: value, participant, guessed_participant (for matching phase)
- **users**: Minimal tracking
- Uses **PostgreSQL with UUIDs** for all primary keys

### Game Flow (3 Phases)
1. **Polling Phase**:
   - Guesser creates round with question
   - Other players submit answers
   - Guesser can start matching when enough answers collected

2. **Matching Phase**:
   - Answers shuffled and assigned to participants randomly
   - Guesser drags/swaps answers to match them to players
   - Service: `MatchRound` handles the shuffle

3. **Completed Phase**:
   - Shows correct matches
   - Guesser can start a new round
   - Service: `CompleteRound` handles transition

### Key Features
- **Answer swapping**: `SwapAnswers` service handles reordering with transactions
- **Soft-delete players**: Players can be removed but data preserved
- **Active player filtering**: Smart filtering based on recent participation
- **Real-time updates**: Turbo Streams + ActionCable (`PlayerChannel`)
- **SortableJS integration**: Drag-and-drop answer matching

### Services
- `MatchRound`: Transition to matching, shuffle answers
- `CompleteRound`: Mark round completed
- `SwapAnswers`: Atomic swap of answer assignments

---

## 3. Burn Unit App (Voting Game)

### Database Schema
Similar structure to Loaded Questions but simpler:
- **votes** table instead of answers
- **judge** instead of guesser
- **Simpler status enum**: polling/completed (no matching phase)
- Fields: `least_likely` (boolean), `hide_voters` (boolean)

### Game Flow (2 Phases)
1. **Polling Phase**:
   - Judge creates round with question
   - Players vote for other players
   - Judge can complete round when votes collected

2. **Completed Phase**:
   - Shows vote tallies
   - Displays winners (most/least likely depending on question)
   - Judge can start new round

### Key Differences from Loaded Questions
- **Simpler**: No matching/guessing mechanic
- **Voting instead of text answers**: Players select from dropdown
- **Vote model**: Much simpler than Answer (just voter → candidate)
- **Tally logic**: Participants track `total_votes`

---

## 4. Comparative Analysis: What's Been Ported

### ✅ Ported to Party
1. **Game creation**: `NewGame` and `NewGameForm`
2. **Player joining**: `NewPlayer` and `NewPlayerForm`
3. **Answer submission**: `AnswerForm` and player answer updates
4. **Status transitions**: Polling → Guessing (with confirmation modal)
5. **Basic game phases**: Polling (as polling), Matching (as guessing)
6. **Real-time connections**: `GameChannel` tracks online players
7. **Player management**: Name normalization, online status
8. **Answer display during guessing**: Shows shuffled answers
9. **Confirmation modals**: Both "Begin Guessing" and "Complete Matching" use dialog modals
10. **System tests**: Comprehensive test coverage for modal interactions and game flow

### ❌ NOT Yet Ported to Party

#### From Loaded Questions:
1. **Multiple rounds per game**
   - Party has single-round state in game document
   - Need to add rounds concept or multi-round document structure

2. **Round completion**
   - No "completed" status in Party
   - Missing completed view/phase

3. **Starting new rounds**
   - No "turn" concept (original has `TurnsController` and `TurnForm`)
   - Can't rotate guesser

4. **Answer matching logic**
   - Party shows answers but has no guess submission
   - No `MatchRound` equivalent
   - Missing `SwapAnswers` functionality

5. **Scoring/Results**
   - No concept of correct vs incorrect matches
   - No score tracking across rounds

6. **Player soft-delete**
   - Party has no `deleted_at` concept
   - Can't remove players mid-game

7. **Active player filtering**
   - No `active_players_since` logic
   - Missing participation tracking

8. **Answer reordering by guesser**
   - Party has swap controller in JS but no backend endpoint
   - Controller has stub `swap_guesses` method

9. **Hide answers toggle**
   - Not implemented in Party game document

10. **Questions config**
    - Original has `config/questions.yml` for seeded questions
    - Party doesn't have this

#### From Burn Unit:
1. **Everything** - Burn Unit has not been ported at all to Party

---

## 5. Architectural Patterns & Recommendations

### Composability Strategy
The Party app's approach is sound:
- **Game-agnostic database schema** ✅
- **Namespace isolation** ✅
- **JSON documents for flexibility** ✅
- **Shared utilities** ✅
- **Type safety with RBS** ✅

### Recommendations for Completing the Migration

#### 1. **Add Rounds Concept**
Two approaches:

**Option A**: Keep document-based, add rounds array
```ruby
document = {
  rounds: [
    { order: 0, question: "...", guesser_id: 1, status: "completed", guesses: [...] },
    { order: 1, question: "...", guesser_id: 2, status: "guessing", guesses: [...] }
  ]
}
```

**Option B**: Add separate rounds table (more normalized)
- Allows for better querying
- Easier to implement pagination
- Closer to original design

**Recommendation**: Option A for consistency with current architecture

#### 2. **Complete the Game Phases**
Add to `LoadedQuestions::Game::Status`:
- `completed` status already exists but needs implementation
- Add transition from guessing → completed
- Add view for completed rounds

#### 3. **Implement Answer Matching**
```ruby
# In LoadedQuestions::Game
def submit_guess(player_id, guessed_player_id)
  guess = guesses.find(player_id)
  guess.update_match(guessed_player_id)
  document[:guesses] = guesses.to_a
  game.save!
end
```

#### 4. **Add Score Tracking**
- Use existing `ScoreMap` class
- Track scores in game document or player document
- Display leaderboard

#### 5. **Port Burn Unit**
Structure would mirror Loaded Questions:
```
/app/games/burn_unit/
  - game.rb
  - player.rb
  - new_game.rb
  - vote_form.rb
  - games_controller.rb
  - players_controller.rb
```

Add to Game model:
```ruby
enum :kind, {
  loaded_questions: 0,
  burn_unit: 1  # Add this
}
```

---

## 6. Missing Features Comparison Table

| Feature | Loaded Questions | Party (LQ) | Burn Unit | Party (BU) |
|---------|------------------|-----------|-----------|-----------|
| Game creation | ✅ | ✅ | ✅ | ❌ |
| Player joining | ✅ | ✅ | ✅ | ❌ |
| Multiple rounds | ✅ | ❌ | ✅ | ❌ |
| Answer submission | ✅ | ✅ | N/A | N/A |
| Voting | N/A | N/A | ✅ | ❌ |
| Matching phase | ✅ | Partial | N/A | N/A |
| Answer swapping | ✅ | ❌ | N/A | N/A |
| Guess submission | ✅ | ❌ | N/A | N/A |
| Scoring | ✅ | ❌ | ✅ | ❌ |
| Round completion | ✅ | ❌ | ✅ | ❌ |
| Starting new turns | ✅ | ❌ | ✅ | ❌ |
| Player soft-delete | ✅ | ❌ | ✅ | ❌ |
| Hide answers/voters | ✅ | ❌ | ✅ | ❌ |
| Real-time updates | ✅ | ✅ | ✅ | ❌ |
| Online indicators | ✅ | ✅ | ✅ | ❌ |

---

## 7. Code Quality Observations

### Party App Strengths
- **Excellent type coverage** with RBS
- **Clean separation** of concerns
- **Thread-safe** shared utilities
- **Modern Rails patterns** (Turbo Streams, Hotwire)
- **Consistent naming** conventions
- **Good use of value objects** (NormalizedString, Status, Guesses)
- **Comprehensive system tests** covering game flow, modal interactions, and real-time features

### Areas for Improvement
1. **Incomplete implementation**: Many stub methods
2. **JSON document validation**: No schema validation for documents
3. **Migration path**: No clear strategy documented for completing ports

### Legacy Apps Strengths
- **Complete, working implementations**
- **Comprehensive validations**
- **Service objects** for complex operations
- **Good use of concerns** (FormModel, LogValidations)
- **Real-time features** working end-to-end

---

## 8. Next Steps Priority

### High Priority (Complete Loaded Questions)
1. ✅ Implement guess submission and matching
2. ✅ Add completed round view
3. ✅ Implement answer swap backend
4. ✅ Add multi-round support
5. ✅ Implement scoring

### Medium Priority
6. ✅ Port player deletion
7. ✅ Add hide_answers toggle
8. ✅ Port questions config
9. ✅ Add comprehensive tests

### Low Priority (New Game)
10. ✅ Port Burn Unit architecture
11. ✅ Implement voting mechanics
12. ✅ Add judge rotation

---

This review provides a complete picture of the migration status and architectural patterns. The Party app's composable design is well-conceived and properly executed where implemented. The primary gap is completion of the game flow beyond the initial polling phase.
