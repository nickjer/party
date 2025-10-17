# frozen_string_literal: true

FactoryBot.define do
  factory :player do
    association :game
    association :user

    name { Faker::Name.unique.first_name }
    document { {}.to_json }
  end
end
