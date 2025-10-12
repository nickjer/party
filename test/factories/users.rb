FactoryBot.define do
  factory :user do
    last_seen_at { Time.current }
  end
end
