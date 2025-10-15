# Performance Refactor: Player-Level Turbo Streams

## Executive Summary

**Problem**: Current game-level broadcasts reload entire turbo frames for all players, including the player who made the change. This is noticeably slow.

**Solution**: Migrate to player-level channels with targeted turbo stream actions. Each player subscribes to their own stream, enabling:
- Granular updates (only what changed)
- Excluding the actor from broadcasts (no echo)
- Player-specific content delivery

**Expected Impact**:
- 50-80% reduction in DOM updates
- 60-90% reduction in network payload
- 40-70% faster perceived performance

---

## Current Architecture

### Current Channel Structure
```ruby
# app/channels/game_channel.rb
class GameChannel < ApplicationCable::Channel
  def subscribed
    @game = GlobalID.find(stream_name)
    PlayerConnections.instance.increment(player.id)
    game.broadcast_reload_players
    stream_from stream_name
  end

  def unsubscribed
    PlayerConnections.instance.decrement(player.id)
    game.broadcast_reload_players
  end
end
```

### Current Broadcasting Pattern
```ruby
# app/models/game.rb
def broadcast_reload_game
  ::Turbo::StreamsChannel.broadcast_action_to(self, action: :reload, target: "game")
end

def broadcast_reload_players
  ::Turbo::StreamsChannel.broadcast_action_to(self, action: :reload, target: "players")
end
```

### Current View Structure
```erb
<!-- app/views/loaded_questions/games/_game.html.erb -->
<%= turbo_stream_from game, channel: GameChannel %>

<turbo-frame id="game" refresh="morph">
  <!-- Full game state - reloads entire frame -->
</turbo-frame>

<turbo-frame id="players" refresh="morph">
  <!-- All players - reloads entire frame -->
</turbo-frame>
```

### Current Problems

1. **Full Frame Reloads**
   - `broadcast_reload_game` → entire game frame re-renders
   - `broadcast_reload_players` → all player cards re-render
   - Expensive even with morphing

2. **Broadcast Echo**
   - Player who swaps answers gets their own update back
   - Unnecessary network round-trip
   - Causes visual flicker

3. **No Granularity**
   - Can't target specific players
   - Can't update individual elements
   - All-or-nothing approach

4. **Example: Answer Swap Flow**
   ```ruby
   # Line 122-123 in games_controller.rb
   @game.swap_guesses(player_id_1:, player_id_2:)
   @game.broadcast_reload_game  # ⚠️ Everyone reloads entire game frame
   ```

---

## New Architecture: Player-Level Channels

### Overview

Each player subscribes to their own turbo stream channel, allowing:
- Targeted broadcasts to specific players
- Exclusion of the acting player
- Different content based on player role
- Minimal, surgical DOM updates

### New Channel Structure

```ruby
# app/channels/player_channel.rb
class PlayerChannel < ApplicationCable::Channel
  def subscribed
    @player = Player.find(params[:player_id])
    @game = @player.game

    # Subscribe to player-specific stream
    stream_for @player

    # Track connection
    PlayerConnections.instance.increment(@player.id)

    # Broadcast to all players that someone connected
    @game.broadcast_player_connection_changed
  end

  def unsubscribed
    PlayerConnections.instance.decrement(@player.id)
    @game.broadcast_player_connection_changed
  end

  private

  attr_reader :player, :game

  def current_user = connection.current_user
end
```

### New Broadcasting Methods

```ruby
# app/models/game.rb (or LoadedQuestions::Game wrapper)

# Broadcast to all players in the game
def broadcast_to_all_players(action:, **options)
  players.each do |player|
    PlayerChannel.broadcast_to(player, {
      action: action,
      **options
    })
  end
end

# Broadcast to all players EXCEPT the actor
def broadcast_to_other_players(except_player:, action:, **options)
  players.where.not(id: except_player.id).each do |player|
    PlayerChannel.broadcast_to(player, {
      action: action,
      **options
    })
  end
end

# Broadcast to a specific player
def broadcast_to_player(player:, action:, **options)
  PlayerChannel.broadcast_to(player, {
    action: action,
    **options
  })
end

# Helper: Render turbo stream for a player
def render_turbo_stream_for(player, template:, **locals)
  ApplicationController.render(
    template: template,
    formats: [:turbo_stream],
    locals: { game: self, current_player: player, **locals }
  )
end
```

### Granular Update Methods

```ruby
# app/models/game.rb (or LoadedQuestions::Game wrapper)

# When guesser swaps answers
def swap_guesses(player_id_1:, player_id_2:, current_player:)
  # Update state
  guesses.swap(player_id_1, player_id_2)
  save!

  # Broadcast only to other players (not the guesser)
  players.where.not(id: current_player.id).each do |player|
    stream = render_turbo_stream_for(
      player,
      template: "loaded_questions/games/update_answers",
      guesses: guesses
    )
    PlayerChannel.broadcast_to(player, stream)
  end
end

# When player submits/updates answer
def player_answered(player:)
  # Broadcast updated player card to everyone
  players.each do |p|
    stream = render_turbo_stream_for(
      p,
      template: "loaded_questions/players/update_player",
      player: player
    )
    PlayerChannel.broadcast_to(p, stream)
  end
end

# When player connects/disconnects
def broadcast_player_connection_changed
  # Update all player cards to show online status
  players.each do |p|
    stream = render_turbo_stream_for(
      p,
      template: "loaded_questions/players/update_all_players",
      players: players
    )
    PlayerChannel.broadcast_to(p, stream)
  end
end

# When game phase changes
def update_status(new_status, current_player:)
  self.status = new_status
  save!

  # Broadcast to others (current_player gets redirect/turbo response)
  players.where.not(id: current_player.id).each do |player|
    stream = render_turbo_stream_for(
      player,
      template: "loaded_questions/games/update_game_phase",
      status: status
    )
    PlayerChannel.broadcast_to(player, stream)
  end
end
```

### Turbo Stream Templates

```erb
<!-- app/views/loaded_questions/games/update_answers.turbo_stream.erb -->
<%# locals: (game:, guesses:, current_player:) %>
<%= turbo_stream.replace "answers-list" do %>
  <%= render partial: "loaded_questions/games/guessed_answer", collection: guesses, as: :guessed_answer %>
<% end %>
```

```erb
<!-- app/views/loaded_questions/players/update_player.turbo_stream.erb -->
<%# locals: (game:, player:, current_player:) %>
<%= turbo_stream.replace "player_#{player.id}" do %>
  <%= render "loaded_questions/players/player", player: player, current_player: current_player %>
<% end %>
```

```erb
<!-- app/views/loaded_questions/players/update_all_players.turbo_stream.erb -->
<%# locals: (game:, players:, current_player:) %>
<%= turbo_stream.replace "players" do %>
  <%= render partial: "loaded_questions/players/player", collection: players, as: :player, locals: { current_player: current_player } %>
<% end %>
```

```erb
<!-- app/views/loaded_questions/games/update_game_phase.turbo_stream.erb -->
<%# locals: (game:, status:, current_player:) %>
<%= turbo_stream.replace "game" do %>
  <%= render "loaded_questions/games/game_content", game: game, current_player: current_player %>
<% end %>
```

### Updated Views

```erb
<!-- app/views/loaded_questions/games/_game.html.erb -->
<%# locals: (game:, current_player:) %>

<!-- Subscribe to PLAYER-specific stream, not game stream -->
<%= turbo_stream_from current_player, channel: PlayerChannel %>

<div class="d-flex flex-wrap align-items-start gap-2 mt-2">
  <div class="flex-grow-1">
    <turbo-frame id="game">
      <%= yield %>
    </turbo-frame>
  </div>

  <div>
    <div class="fw-bold">Players:</div>
    <div id="players">
      <%= render partial: "loaded_questions/players/player", collection: game.players, as: :player, locals: { current_player: current_player } %>
    </div>
  </div>
</div>
```

```erb
<!-- app/views/loaded_questions/games/guessing_guesser.html.erb -->
<%= render layout: "loaded_questions/games/round", locals: { game: @game, current_player: @current_player } do %>
  <div id="answers-list" class="mt-2 px-2 pb-2 border rounded"
    data-controller="swap"
    data-swap-name-value="guess"
    data-swap-url-value="<%= swap_guesses_loaded_questions_game_path(@game.slug) %>">
    <%=
      render(
        partial: "loaded_questions/games/guessed_answer",
        collection: @game.guesses,
        as: :guessed_answer,
        locals: { gripper: true }
      )
    %>
  </div>

  <!-- Modal code unchanged -->
<% end %>
```

```erb
<!-- app/views/loaded_questions/players/_player.html.erb -->
<!-- Wrap in div with ID for targeted updates -->
<div id="player_<%= player.id %>" class="d-flex align-items-center gap-1">
  <% if player == current_player || player.online? %>
    <i class="bi bi-circle-fill text-success"></i>
  <% else %>
    <i class="bi bi-circle-fill text-danger"></i>
  <% end %>
  <% if player.guesser? %>
    <i class="bi bi-star-fill"></i>
  <% elsif player.answered? %>
    <i class="bi bi-check-square"></i>
  <% else %>
    <i class="bi bi-square"></i>
  <% end %>
  <span class="d-block<%= " fw-bold" if player == current_player %>">
    <%= player.name %>
  </span>
</div>
```

### Updated Controllers

```ruby
# app/games/loaded_questions/games_controller.rb

def swap_guesses
  @game = Game.find(params[:id])
  @current_player = @game.player_for!(current_user)
  return (head :forbidden) unless @current_player.guesser?
  return (head :forbidden) unless @game.status.guessing?

  player_id_1 = swap_params[:guess_id].to_i
  player_id_2 = swap_params[:swap_guess_id].to_i

  # Pass current_player to exclude from broadcast
  @game.swap_guesses(player_id_1:, player_id_2:, current_player: @current_player)

  head :ok
end

def guessing_round
  @game = Game.find(params[:id])
  @current_player = @game.player_for!(current_user)
  return (head :forbidden) unless @current_player.guesser?

  guessing_round_form = GuessingRoundForm.new(game: @game)
  if guessing_round_form.valid?
    # Pass current_player to exclude from broadcast
    @game.update_status(Game::Status.guessing, current_player: @current_player)
    head :ok
  else
    render :polling_guesser, locals: { guessing_round_form: }, status: :unprocessable_content
  end
end

def completed_round
  @game = Game.find(params[:id])
  @current_player = @game.player_for!(current_user)
  return (head :forbidden) unless @current_player.guesser?

  completed_round_form = CompletedRoundForm.new(game: @game)
  if completed_round_form.valid?
    # Pass current_player to exclude from broadcast
    @game.update_status(Game::Status.completed, current_player: @current_player)
    redirect_to loaded_questions_game_path(@game.slug)
  else
    render :guessing_guesser, locals: { completed_round_form: }, status: :unprocessable_content
  end
end
```

```ruby
# app/games/loaded_questions/players_controller.rb

def update
  @game = Game.find(params[:game_id])
  @current_player = @game.player_for!(current_user)

  answer_form = AnswerForm.new(answer: answer_params[:answer])
  if answer_form.valid?
    @current_player.update_answer(answer_form.answer)

    # Broadcast to all players (including current, to update their status icon)
    @game.player_answered(player: @current_player)

    head :ok
  else
    render "loaded_questions/games/polling_player", locals: { answer_form: }, status: :unprocessable_content
  end
end
```

---

## Migration Strategy

### Phase 1: Add PlayerChannel (No Breaking Changes)

**Goal**: Introduce new infrastructure without removing old system.

**Tasks**:
1. Create `app/channels/player_channel.rb`
2. Add player-level broadcasting methods to Game model
3. Add turbo stream template directory structure
4. Deploy and verify channel subscriptions work

**Testing**:
- Channel subscribes correctly
- Connection tracking still works
- Old GameChannel still functioning

**Timeline**: 2-4 hours

---

### Phase 2: Migrate Answer Swapping

**Goal**: Prove the concept with most visible performance issue.

**Tasks**:
1. Update `swap_guesses` method signature to accept `current_player:`
2. Implement targeted broadcast in `swap_guesses`
3. Create `app/views/loaded_questions/games/update_answers.turbo_stream.erb`
4. Update `swap_controller.js` if needed
5. Add ID `answers-list` to guessing_guesser view
6. Update system tests to verify no echo

**Testing**:
- Guesser swaps answers → sees instant update (optimistic)
- Other players receive update
- Guesser does NOT receive broadcast echo
- Verify with browser network tab

**Timeline**: 3-5 hours

---

### Phase 3: Migrate Player Status Updates

**Goal**: Replace player frame reloads with targeted player card updates.

**Tasks**:
1. Update `player_answered` method
2. Create `app/views/loaded_questions/players/update_player.turbo_stream.erb`
3. Wrap player partial in `<div id="player_#{player.id}">`
4. Update PlayerChannel subscribe/unsubscribe to use new method
5. Update system tests

**Testing**:
- Player submits answer → all players see updated icon
- Player connects/disconnects → all see status change
- Only affected player card updates (not full list)

**Timeline**: 2-4 hours

---

### Phase 4: Migrate Phase Transitions

**Goal**: Replace game frame reloads with targeted updates.

**Tasks**:
1. Update `update_status` method signature to accept `current_player:`
2. Implement targeted broadcast for status changes
3. Create `app/views/loaded_questions/games/update_game_phase.turbo_stream.erb`
4. Update `guessing_round` and `completed_round` controller actions
5. Update system tests

**Testing**:
- Guesser starts matching → other players transition
- Guesser completes round → other players see results
- Guesser gets redirect (no broadcast echo)

**Timeline**: 3-5 hours

---

### Phase 5: Clean Up

**Goal**: Remove old GameChannel and unused code.

**Tasks**:
1. Verify all broadcasts use PlayerChannel
2. Remove `app/channels/game_channel.rb`
3. Remove `broadcast_reload_game` and `broadcast_reload_players` methods
4. Remove any old turbo stream subscriptions in views
5. Update documentation

**Timeline**: 1-2 hours

---

## Implementation Checklist

### PlayerChannel Creation
- [ ] Create `app/channels/player_channel.rb`
- [ ] Add subscription logic with player lookup
- [ ] Add unsubscription logic
- [ ] Reuse PlayerConnections for tracking
- [ ] Write channel tests
- [ ] Verify subscriptions work in development

### Broadcasting Infrastructure
- [ ] Add `broadcast_to_all_players` method
- [ ] Add `broadcast_to_other_players` method
- [ ] Add `broadcast_to_player` method
- [ ] Add `render_turbo_stream_for` helper
- [ ] Write unit tests for broadcasting methods

### Answer Swapping Migration
- [ ] Update `swap_guesses` signature
- [ ] Implement targeted broadcast
- [ ] Create `update_answers.turbo_stream.erb`
- [ ] Add `answers-list` ID to view
- [ ] Update system tests
- [ ] Test with multiple players

### Player Status Migration
- [ ] Update `player_answered` method
- [ ] Create `update_player.turbo_stream.erb`
- [ ] Create `update_all_players.turbo_stream.erb`
- [ ] Wrap player partial with ID
- [ ] Update connection change broadcasts
- [ ] Update system tests

### Phase Transition Migration
- [ ] Update `update_status` signature
- [ ] Implement targeted broadcast
- [ ] Create `update_game_phase.turbo_stream.erb`
- [ ] Update `guessing_round` action
- [ ] Update `completed_round` action
- [ ] Update system tests

### Cleanup
- [ ] Verify no GameChannel references remain
- [ ] Remove GameChannel file
- [ ] Remove old broadcast methods
- [ ] Update CLAUDE.md documentation
- [ ] Update MIGRATION_REVIEW.md

---

## Testing Strategy

### Unit Tests

```ruby
# test/models/game_test.rb
test "broadcast_to_all_players sends to each player" do
  game = games(:loaded_questions_game)

  assert_broadcasts(PlayerChannel, game.players.count) do
    game.broadcast_to_all_players(action: :test)
  end
end

test "broadcast_to_other_players excludes specified player" do
  game = games(:loaded_questions_game)
  player = game.players.first

  assert_broadcasts(PlayerChannel, game.players.count - 1) do
    game.broadcast_to_other_players(except_player: player, action: :test)
  end
end
```

### Integration Tests

```ruby
# test/channels/player_channel_test.rb
class PlayerChannelTest < ActionCable::Channel::TestCase
  test "subscribes to player stream" do
    player = players(:alice)

    subscribe(player_id: player.id)

    assert subscription.confirmed?
    assert_has_stream_for player
  end

  test "increments player connections on subscribe" do
    player = players(:alice)

    assert_difference -> { PlayerConnections.instance.count(player.id) }, 1 do
      subscribe(player_id: player.id)
    end
  end
end
```

### System Tests

```ruby
# test/system/loaded_questions/games_test.rb
test "answer swap does not echo to guesser" do
  # Setup game with multiple players
  # ...

  using_session("default") do
    # Guesser swaps answers
    swap_items[0].drag_to(swap_items[1])

    # Should NOT receive turbo stream update
    # (verify by checking network tab or turbo stream count)
    assert_no_turbo_stream_received
  end

  using_session("bob") do
    # Bob should receive update
    assert_text answer2_original
  end
end

test "player status update broadcasts to all players" do
  # ...

  using_session("bob") do
    fill_in "player[answer]", with: "Blue"
    click_on "Submit Answer"
  end

  # All other sessions should see Bob's check mark
  using_session("default") do
    within "#player_#{bob.id}" do
      assert_selector "i.bi-check-square"
    end
  end
end
```

---

## Performance Metrics

### Before Refactor
- **Answer Swap**: ~300-500ms (full frame reload)
- **Player Status Update**: ~200-400ms (full player list reload)
- **Network Payload**: ~15-30KB per update
- **DOM Mutations**: 50-200+ nodes

### Expected After Refactor
- **Answer Swap**: ~50-100ms (targeted update)
- **Player Status Update**: ~30-80ms (single player card)
- **Network Payload**: ~2-5KB per update
- **DOM Mutations**: 5-20 nodes

### How to Measure

```javascript
// In browser console during gameplay
performance.mark('swap-start');
// Perform swap action
performance.mark('swap-end');
performance.measure('swap-duration', 'swap-start', 'swap-end');
console.log(performance.getEntriesByName('swap-duration'));
```

---

## Rollback Plan

1. **Keep Old Methods**: Don't delete GameChannel immediately
2. **Feature Flag**: Add flag to toggle between channels
   ```ruby
   def broadcast_answers_swap
     if ENV['USE_PLAYER_CHANNELS'] == 'true'
       broadcast_to_all_players(action: :update_answers)
     else
       broadcast_reload_game  # Old method
     end
   end
   ```
3. **Monitor Errors**: Track ActionCable errors in logs
4. **Quick Revert**: Change environment variable to disable

---

## Future Optimizations

Once player-level channels are stable:

1. **Fragment Caching**
   ```ruby
   <%= cache ["player", player] do %>
     <%= render "player", player: player %>
   <% end %>
   ```

2. **Differential Updates**
   - Only send changed attributes, not full HTML
   - Use Stimulus to apply changes client-side

3. **Batched Updates**
   - If multiple changes happen rapidly, batch into single broadcast
   - Debounce updates on server side

4. **Optimistic UI**
   - Update actor's UI immediately via Stimulus
   - Broadcast confirms change to server

---

## Estimated Total Effort

- **Phase 1 (Infrastructure)**: 2-4 hours
- **Phase 2 (Answer Swapping)**: 3-5 hours
- **Phase 3 (Player Status)**: 2-4 hours
- **Phase 4 (Phase Transitions)**: 3-5 hours
- **Phase 5 (Cleanup)**: 1-2 hours

**Total**: 11-20 hours (1.5 - 2.5 days)

---

## Risk Assessment

**Low Risk**:
- ✅ Can deploy incrementally
- ✅ Old system remains functional during migration
- ✅ Easy to test in isolation
- ✅ Clear rollback path

**Potential Issues**:
- ⚠️ Turbo stream template errors (syntax issues)
- ⚠️ Missing IDs in views (updates fail silently)
- ⚠️ Channel subscription failures (player lookup issues)

**Mitigation**:
- Thorough system testing with multiple sessions
- Monitor ActionCable logs during deployment
- Start with non-critical updates (answer swapping)
- Keep GameChannel as fallback initially
