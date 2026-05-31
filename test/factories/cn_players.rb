# frozen_string_literal: true

FactoryBot.define do
  factory :cn_player, class: "Codenames::Player" do
    user
    name { Faker::Name.unique.first_name.ljust(3, "a") }
    team { nil }
    spymaster { false }
    game { association :cn_game }

    initialize_with do
      game.add_player(
        user_id: user.id, name: PlayerName.parse(name), team:, spymaster:
      )
    end

    to_create do |_player, evaluator|
      Codenames::GameRepo.new.save(evaluator.game)
    end
  end
end
