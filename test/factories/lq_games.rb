# frozen_string_literal: true

FactoryBot.define do
  factory :lq_game, class: "LoadedQuestions::Game" do
    transient do
      user { association(:user) }
      guesser { Faker::Name.unique.first_name.ljust(3, "a") }
      question { Faker::Lorem.question }
      player_names { [] }
      players { player_names.map { |name| { name:, answer: nil } } }
    end

    skip_create

    initialize_with do
      form = LoadedQuestions::NewGameForm.new(player_name: guesser, question:)

      unless form.valid?
        raise "Invalid game form: #{form.errors.full_messages.join(', ')}"
      end

      game = LoadedQuestions::CreateNewGame.new(
        user:,
        player_name: form.player_name,
        question: form.question
      ).call
      game.save!

      players.each do |player_data|
        player = create(:lq_player, game:, name: player_data.fetch(:name))

        # Add answer if provided
        answer = player_data.fetch(:answer)
        next unless answer.present? && !player.guesser?

        answer_form = LoadedQuestions::AnswerForm.new(answer:)
        unless answer_form.valid?
          raise "Invalid answer: #{answer_form.errors.full_messages.join(', ')}"
        end

        player.answer = answer_form.answer
        player.save!
      end

      LoadedQuestions::Game.find(game.id)
    end

    trait :with_players do
      transient do
        player_names { Array.new(2) { Faker::Name.unique.first_name.ljust(3, "a") } }
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
    end

    factory :lq_matching_game, traits: %i[with_players with_answers] do
      initialize_with do
        # Create base game with players and answers
        game = build(:lq_game, user:, guesser:, question:, player_names:,
          players:)

        # Transition to guessing status
        game = LoadedQuestions::Game.find(game.id)
        LoadedQuestions::BeginGuessingRound.new(game:).call
        game.save!

        LoadedQuestions::Game.find(game.id)
      end
    end

    factory :lq_completed_game, traits: %i[with_players with_answers] do
      initialize_with do
        # Create matching game (with guessing status)
        game = build(:lq_matching_game, user:, guesser:, question:,
          player_names:, players:)

        # Transition to completed status
        game = LoadedQuestions::Game.find(game.id)
        LoadedQuestions::CompleteRound.new(game:).call
        game.save!

        LoadedQuestions::Game.find(game.id)
      end
    end
  end
end
