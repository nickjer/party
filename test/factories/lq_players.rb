# frozen_string_literal: true

FactoryBot.define do
  factory :lq_player, class: "LoadedQuestions::Player" do
    transient do
      user { association :user }
      name { Faker::Name.unique.first_name.ljust(3, "a") }
      guesser { false }
      answer { nil }
    end

    game { association :lq_game }

    skip_create

    initialize_with do
      form = LoadedQuestions::NewPlayerForm.new(game:, user:, name:)

      raise "Invalid player form: #{form.errors}" unless form.valid?

      player_record =
        LoadedQuestions::NewPlayer.new(user:, name: form.name, guesser:).build
      player_record.game_id = form.game.id
      player_record.save!

      player = LoadedQuestions::Game.from_slug(game.slug).player_for!(user)

      # Add answer if provided
      if answer.present?
        answer_form = LoadedQuestions::AnswerForm.new(answer:)
        unless answer_form.valid?
          raise "Invalid answer: #{answer_form.errors.full_messages.join(', ')}"
        end

        player.update_answer(answer_form.answer)
      end

      player
    end

    trait :with_answer do
      answer { Faker::Lorem.sentence(word_count: 3) }
    end
  end
end
