# frozen_string_literal: true

FactoryBot.define do
  factory :lq_game, class: "LoadedQuestions::Game" do
    question { Faker::Lorem.question }

    initialize_with do
      LoadedQuestions::Game.build(question:)
    end

    trait :with_guesser do
      transient do
        guesser_name { Faker::Name.unique.first_name.ljust(3, "a") }
        guesser do
          association(:lq_player, game: instance, name: guesser_name,
            guesser: true, strategy: :build)
        end
      end

      after(:build) do |game, context|
        game.players << context.guesser
      end
    end

    trait :with_players do
      transient do
        player_names { Array.new(2) { Faker::Name.unique.first_name.ljust(3, "a") } }
        players { player_names.map { |name| { name:, answer: nil } } }
      end

      after(:build) do |game, context|
        context.players.each do |player_data|
          player = build(:lq_player,
            game:,
            name: player_data.fetch(:name),
            guesser: false,
            answer: player_data.fetch(:answer))
          game.players << player
        end
      end
    end

    trait :with_answers do
      with_players

      transient do
        players do
          player_names.map do |name|
            { name:, answer: Faker::Lorem.sentence(word_count: 3) }
          end
        end
      end
    end

    factory :lq_polling_game, traits: %i[with_guesser with_players]

    factory :lq_matching_game,
      traits: %i[with_guesser with_players with_answers] do
      after(:build) do |game|
        LoadedQuestions::BeginGuessingRound.new(game:).call
      end
    end

    factory :lq_completed_game,
      traits: %i[with_guesser with_players with_answers] do
      after(:build) do |game|
        LoadedQuestions::BeginGuessingRound.new(game:).call
        LoadedQuestions::CompleteRound.new(game:).call
      end
    end
  end
end
