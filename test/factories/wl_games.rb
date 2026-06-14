# frozen_string_literal: true

FactoryBot.define do
  factory :wl_game, class: "Wavelength::Game" do
    transient do
      starting_team { Wavelength::Team.red }
      # Deterministic target for predictable scoring tests; override per test.
      target_position { 50 }
    end

    initialize_with do
      Wavelength::Game.build(
        spectrum: Wavelength::Spectrums.instance.sample,
        target: Wavelength::Game::Target.new(position: target_position),
        starting_team:
      )
    end

    to_create { |game| Wavelength::GameRepo.save(game) }

    trait :with_teams do
      transient do
        red1 { association(:user) }
        red2 { association(:user) }
        blue1 { association(:user) }
        blue2 { association(:user) }
      end

      after(:build) do |game, context|
        build(:wl_player, game:, user: context.red1,
          name: "RedOne", team: Wavelength::Team.red)
        build(:wl_player, game:, user: context.red2,
          name: "RedTwo", team: Wavelength::Team.red)
        build(:wl_player, game:, user: context.blue1,
          name: "BlueOne", team: Wavelength::Team.blue)
        build(:wl_player, game:, user: context.blue2,
          name: "BlueTwo", team: Wavelength::Team.blue)
      end
    end

    factory :wl_clue_game, traits: %i[with_teams] do
      after(:build) { |game| game.start_game(psychic: game.suggested_psychic) }
    end

    factory :wl_guessing_game, traits: %i[with_teams] do
      after(:build) do |game|
        game.start_game(psychic: game.suggested_psychic)
        game.submit_clue(text: "Clue")
      end
    end

    # An off-center lock (no bullseye) so the opponent still gets a left/right
    # guess; the game waits in the left_right phase.
    factory :wl_left_right_game, traits: %i[with_teams] do
      after(:build) do |game|
        game.start_game(psychic: game.suggested_psychic)
        game.submit_clue(text: "Clue")
        game.lock_guess(position: 70)
      end
    end

    # A dead-center bullseye settles the round outright (no left/right step),
    # landing in the reveal phase.
    factory :wl_reveal_game, traits: %i[with_teams] do
      after(:build) do |game|
        game.start_game(psychic: game.suggested_psychic)
        game.submit_clue(text: "Clue")
        game.lock_guess(position: 50)
      end
    end

    # Repeated dead-center bullseyes; the active team alternates, so the
    # starting team reaches WIN_SCORE first (4 + 4 + 4 = 12 on its 3rd turn).
    factory :wl_completed_game, traits: %i[with_teams] do
      after(:build) do |game|
        game.start_game(psychic: game.suggested_psychic)
        game.submit_clue(text: "Clue")
        loop do
          game.lock_guess(position: 50)
          break if game.status.completed?

          game.start_new_round(
            psychic: game.suggested_psychic,
            spectrum: Wavelength::Spectrums.instance.sample,
            target: Wavelength::Game::Target.new(position: 50)
          )
          game.submit_clue(text: "Clue")
        end
      end
    end
  end
end
