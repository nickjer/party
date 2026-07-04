# frozen_string_literal: true

module Wavelength
  # PlayerChannel adapter: presence changes re-render the player's row.
  Adapter = PresenceAdapter.new(repo: GameRepo,
    template: "wavelength/players/presence")
end
