# frozen_string_literal: true

# PlayerChannel adapter that re-renders the acting player's row for the
# other online players when that player connects or disconnects.
class PresenceAdapter
  def initialize(repo:, template:)
    @repo = repo
    @template = template
  end

  def on_player_connected(player_id) = broadcast(player_id)

  def on_player_disconnected(player_id) = broadcast(player_id)

  private

  # @dynamic repo, template
  attr_reader :repo, :template

  def broadcast(player_id)
    record = ::Player.find(player_id)
    game = repo.find(record.game_id)
    player = game.find_player(record.id)

    PlayerBroadcaster.new(players: game.players).broadcast do |current_player|
      next if current_player.id == player.id

      ApplicationController.render(
        template,
        formats: [:turbo_stream],
        locals: { current_player:, player: }
      )
    end
  end
end
