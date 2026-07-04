# frozen_string_literal: true

module Codenames
  # PlayerChannel adapter: presence changes re-render the player's row.
  Adapter = PresenceAdapter.new(repo: GameRepo,
    template: "codenames/players/presence")
end
