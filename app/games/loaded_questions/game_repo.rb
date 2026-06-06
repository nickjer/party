# frozen_string_literal: true

module LoadedQuestions
  # Persistence boundary for Loaded Questions: a GameStore wired with the
  # Loaded Questions mapping.
  GameRepo = GameStore.new(mapping: GameMapping.new)
end
