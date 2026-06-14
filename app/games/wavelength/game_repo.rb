# frozen_string_literal: true

module Wavelength
  # Persistence boundary for Wavelength: a GameStore wired with the Wavelength
  # mapping.
  GameRepo = GameStore.new(mapping: GameMapping.new)
end
