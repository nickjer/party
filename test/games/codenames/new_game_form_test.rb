# frozen_string_literal: true

require "test_helper"

module Codenames
  class NewGameFormTest < ActiveSupport::TestCase
    test "#valid? returns true with a valid player name" do
      form = NewGameForm.new(player_name: "Alice")

      assert_predicate form, :valid?
      assert_instance_of PlayerName, form.player_name
    end

    test "#valid? returns false with a name too short" do
      form = NewGameForm.new(player_name: "ab")

      assert_not_predicate form, :valid?
      assert form.errors.added?(:player_name,
        message: "is too short (minimum is 3 characters)")
    end

    test "#valid? returns false with a blank name" do
      form = NewGameForm.new(player_name: "")

      assert_not_predicate form, :valid?
    end

    test "#valid? normalizes the player name" do
      form = NewGameForm.new(player_name: "  Alice  ")

      assert_predicate form, :valid?
      assert_equal "Alice", form.player_name_input.to_s
    end

    test "#valid? applies the name easter egg" do
      form = NewGameForm.new(player_name: "Bethany")

      assert_predicate form, :valid?
      assert_equal "Betsy", form.player_name_input.to_s
    end
  end
end
