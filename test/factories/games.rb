# frozen_string_literal: true

FactoryBot.define do
  factory :game do
    traits_for_enum :kind, %i[loaded_questions]
    loaded_questions

    document { {}.to_json }
  end
end
