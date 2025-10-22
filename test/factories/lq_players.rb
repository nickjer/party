# frozen_string_literal: true

FactoryBot.define do
  factory :lq_player, class: "LoadedQuestions::Player" do
    user { association :user, strategy: :create }
    name { Faker::Name.unique.first_name.ljust(3, "a") }
    guesser { false }
    answer { nil }
    game { association :lq_game }

    initialize_with do
      player = LoadedQuestions::Player.build(
        game_id: game.id,
        user_id: user.id,
        name:,
        guesser:
      )

      player.answer = NormalizedString.new(answer) if answer.present?

      player
    end

    trait :with_answer do
      answer { Faker::Lorem.sentence(word_count: 3) }
    end
  end
end
