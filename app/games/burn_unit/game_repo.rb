# frozen_string_literal: true

module BurnUnit
  # Persistence boundary for Burn Unit: a GameStore wired with the Burn Unit
  # mapping.
  GameRepo = GameStore.new(mapping: GameMapping.new)
end
