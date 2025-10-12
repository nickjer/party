FactoryBot.define do
  factory :player do
    association :game
    association :user

    sequence(:name) { |n| "Player#{n}" }
    document { {}.to_json }
  end
end
