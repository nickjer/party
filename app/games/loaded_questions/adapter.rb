# frozen_string_literal: true

module LoadedQuestions
  # PlayerChannel adapter: presence changes re-render the player's row.
  Adapter = PresenceAdapter.new(repo: GameRepo,
    template: "loaded_questions/players/presence")
end
