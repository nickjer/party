# frozen_string_literal: true

module Codenames
  # Persistence boundary for Codenames: a GameStore wired with the Codenames
  # mapping.
  GameRepo = GameStore.new(mapping: GameMapping.new)
end
