# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    last_seen_at { Time.current }
  end
end
