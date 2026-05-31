# frozen_string_literal: true

FactoryBot.define do
  factory :cn_game, class: "Codenames::Game" do
    transient do
      starting_team { Codenames::Team.red }
    end

    initialize_with do
      Codenames::Game.build(
        words: Codenames::Words.instance.sample, starting_team:
      )
    end

    to_create do |game|
      Codenames::GameRepo.new.save(game)
    end

    trait :with_teams do
      transient do
        red_spy_user { association(:user) }
        red_op_user { association(:user) }
        blue_spy_user { association(:user) }
        blue_op_user { association(:user) }
      end

      after(:build) do |game, context|
        build(:cn_player, game:, user: context.red_spy_user,
          name: "RedSpy", team: Codenames::Team.red, spymaster: true)
        build(:cn_player, game:, user: context.red_op_user,
          name: "RedOp", team: Codenames::Team.red)
        build(:cn_player, game:, user: context.blue_spy_user,
          name: "BlueSpy", team: Codenames::Team.blue, spymaster: true)
        build(:cn_player, game:, user: context.blue_op_user,
          name: "BlueOp", team: Codenames::Team.blue)
      end
    end

    factory :cn_playing_game, traits: %i[with_teams] do
      after(:build, &:start_game)
    end

    factory :cn_completed_game, traits: %i[with_teams] do
      after(:build) do |game|
        game.start_game
        game.board.cards.each_with_index do |card, index|
          next if card.identity.team != game.starting_team
          next if game.status.completed?

          game.reveal(index:)
        end
      end
    end
  end
end
