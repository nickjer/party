# frozen_string_literal: true

FactoryBot.define do
  factory :bu_game, class: "BurnUnit::Game" do
    question { Faker::Lorem.question }

    initialize_with do
      BurnUnit::Game.build(question:)
    end

    trait :with_judge do
      transient do
        judge_user { association :user }
        judge_name { "Judge" }
      end

      after(:build) do |game, context|
        build(:bu_player, game:, user: context.judge_user,
          name: context.judge_name, judge: true, playing: true)
      end
    end

    trait :with_players do
      transient do
        player_names do
          Array.new(2) { Faker::Name.unique.first_name.ljust(3, "a") }
        end
        players { player_names.map { |name| { name: } } }
        users { players.map { association(:user) } }
      end

      after(:build) do |game, context|
        players_with_votes =
          context.players.zip(context.users).map do |player_data, user|
            not_playing = player_data.fetch(:not_playing, false)
            player = build(:bu_player, game:, user:,
              name: player_data.fetch(:name),
              judge: false,
              playing: !not_playing)
            [player, player_data[:vote_for]]
          end

        # Set up votes after all players are created
        players_with_votes.each do |player, vote_for_name|
          next if vote_for_name.nil?

          candidate = game.players.find { |p| p.name.to_s == vote_for_name }
          player.vote = candidate.id if candidate
        end
      end
    end

    factory :bu_polling_game, traits: %i[with_judge with_players]

    factory :bu_completed_game, traits: %i[with_judge with_players] do
      after(:build) do |game|
        BurnUnit::CompleteRound.new(game:).call
      end
    end
  end
end
