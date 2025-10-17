# frozen_string_literal: true

FactoryBot.define do
  factory :loaded_questions_player, class: "LoadedQuestions::Player" do
    transient do
      user { create(:user) }
      name { Faker::Name.unique.first_name }
      guesser { false }
    end

    association :game, factory: :loaded_questions_game

    skip_create

    initialize_with do
      form = LoadedQuestions::NewPlayerForm.new(game:, name:)

      raise "Invalid player form: #{form.errors}" unless form.valid?

      player_record =
        LoadedQuestions::NewPlayer.new(user:, name: form.name, guesser:).build
      player_record.game_id = form.game.id
      player_record.save!

      LoadedQuestions::Game.find(game.slug).player_for!(user)
    end
  end
end
