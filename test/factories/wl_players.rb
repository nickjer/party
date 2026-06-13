# frozen_string_literal: true

FactoryBot.define do
  factory :wl_player, class: "Wavelength::Player" do
    user
    name { Faker::Name.unique.first_name.ljust(3, "a") }
    team { nil }
    game { association :wl_game }

    initialize_with do
      game.add_player(user_id: user.id, name: PlayerName.parse(name), team:)
    end

    to_create do |_player, evaluator|
      Wavelength::GameRepo.save(evaluator.game)
    end
  end
end
