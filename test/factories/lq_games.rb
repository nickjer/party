# frozen_string_literal: true

FactoryBot.define do
  factory :lq_game, class: "LoadedQuestions::Game" do
    question { Faker::Lorem.question }

    initialize_with do
      LoadedQuestions::Game.build(question:)
    end

    trait :with_guesser do
      transient do
        guesser_user { association :user }
        guesser_name { Faker::Name.unique.first_name.ljust(3, "a") }
      end

      after(:build) do |game, context|
        build(:lq_player, game:, user: context.guesser_user,
          name: context.guesser_name, guesser: true)
      end
    end

    trait :with_players do
      transient do
        player_names do
          Array.new(2) { Faker::Name.unique.first_name.ljust(3, "a") }
        end
        players { player_names.map { |name| { name:, answer: nil } } }
        users { players.map { association(:user) } }
      end

      after(:build) do |game, context|
        context.players.zip(context.users).each do |player_data, user|
          build(:lq_player, game:, user:, name: player_data.fetch(:name),
            guesser: false, answer: player_data.fetch(:answer))
        end
      end
    end

    trait :with_answers do
      transient do
        players do
          player_names.map do |name|
            { name:, answer: Faker::Lorem.sentence(word_count: 3) }
          end
        end
      end

      with_players
    end

    factory :lq_polling_game, traits: %i[with_guesser with_players]

    factory :lq_matching_game, traits: %i[with_guesser with_answers] do
      after(:build) do |game|
        LoadedQuestions::BeginGuessingRound.new(game:).call
      end
    end

    factory :lq_completed_game, traits: %i[with_guesser with_answers] do
      after(:build) do |game|
        LoadedQuestions::BeginGuessingRound.new(game:).call
        LoadedQuestions::CompleteRound.new(game:).call
      end
    end
  end
end
