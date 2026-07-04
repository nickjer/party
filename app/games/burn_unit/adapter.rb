# frozen_string_literal: true

module BurnUnit
  # PlayerChannel adapter: presence changes re-render the player's row.
  Adapter = PresenceAdapter.new(repo: GameRepo,
    template: "burn_unit/players/presence")
end
