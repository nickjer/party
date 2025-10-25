# frozen_string_literal: true

FactoryBot.define do
  factory :bu_player, class: "BurnUnit::Player" do
    user
    name { Faker::Name.unique.first_name.ljust(3, "a") }
    judge { false }
    playing { false }
    game { association :bu_game }

    initialize_with do
      game.add_player(user_id: user.id, name:, judge:, playing:)
    end
  end
end
