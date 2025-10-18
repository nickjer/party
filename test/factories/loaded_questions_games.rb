# frozen_string_literal: true

FactoryBot.define do
  factory :loaded_questions_game, class: "LoadedQuestions::Game" do
    transient do
      user { association(:user) }
      guesser { Faker::Name.unique.first_name }
      question { Faker::Lorem.question }
      players { [] }
    end

    skip_create

    initialize_with do
      form = LoadedQuestions::NewGameForm.new(player_name: guesser, question:)

      unless form.valid?
        raise "Invalid game form: #{form.errors[:base].join(', ')}"
      end

      game_record = LoadedQuestions::CreateNewGame.new(
        user:,
        player_name: form.player_name,
        question: form.question
      ).call

      game = LoadedQuestions::Game.from_slug(game_record.slug)
      players.each do |player_name|
        create(:loaded_questions_player, game:, name: player_name)
      end

      LoadedQuestions::Game.from_slug(game.slug)
    end
  end
end
