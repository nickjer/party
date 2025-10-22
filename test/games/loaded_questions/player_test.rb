# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class PlayerTest < ActiveSupport::TestCase
    test ".build raises error when name is too short" do
      game = build(:lq_game)
      user = build(:user)
      short_name = NormalizedString.new("AB")

      error = assert_raises(ArgumentError) do
        Player.build(game_id: game.id, user_id: user.id, name: short_name)
      end

      assert_match(/Name length must be between 3 and 25 characters/,
        error.message)
    end
  end
end
